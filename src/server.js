const { connect, StringCodec } = require('nats');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

const sc = StringCodec();

// NATS connection configuration
const natsUrl = process.env.NATS_URL || 'nats://localhost:4222';
const subject = process.env.NATS_SUBJECT || 'mermaid.render';
const outputDir = process.env.OUTPUT_DIR || '/data/output';

process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

async function processMermaidCode(mermaidCode, outputFormat = 'png') {
    console.log('Processing mermaid code with format:', outputFormat);
    const timestamp = new Date().getTime();
    const inputFile = path.join(outputDir, `input_${timestamp}.mmd`);
    const outputFile = path.join(outputDir, `diagram_${timestamp}.${outputFormat}`);

    try {
        console.log('Writing mermaid code to:', inputFile);
        await fs.writeFile(inputFile, mermaidCode, 'utf8');
        console.log('Successfully wrote input file');

        const command = `/home/mermaidcli/node_modules/.bin/mmdc -p /puppeteer-config.json -i "${inputFile}" -o "${outputFile}"`;
        console.log('Executing command:', command);
        
        const result = await new Promise((resolve, reject) => {
            exec(command, (error, stdout, stderr) => {
                if (error) {
                    console.error('Command execution error:', error);
                    console.error('stderr:', stderr);
                    reject({ error, stderr });
                    return;
                }
                if (stderr) {
                    console.warn('Command warnings:', stderr);
                }
                console.log('Command output:', stdout);
                resolve({
                    outputFile,
                    stdout
                });
            });
        });

        return result;
    } catch (error) {
        console.error('Error in processMermaidCode:', error);
        throw error;
    } finally {
        try {
            // 確保命令執行完成後再刪除臨時文件
            await fs.unlink(inputFile);
            console.log('Cleaned up input file:', inputFile);
        } catch (e) {
            console.error('Error cleaning up input file:', e);
        }
    }
}

async function main() {
    console.log('Starting Mermaid CLI service...');
    console.log('NATS URL:', natsUrl);
    console.log('Subject:', subject);
    console.log('Output directory:', outputDir);

    try {
        console.log('Creating output directory...');
        await fs.mkdir(outputDir, { recursive: true });

        console.log('Connecting to NATS...');
        const nc = await connect({ 
            servers: natsUrl,
            timeout: 3000,
            reconnect: true,
            maxReconnectAttempts: 10
        });
        
        console.log('Connected to NATS');
        console.log('Subscribing to:', subject);

        const sub = nc.subscribe(subject);
        console.log('Subscription created');
        
        for await (const msg of sub) {
            console.log('Received message');
            const data = sc.decode(msg.data);
            console.log('Decoded message data:', data);
            
            try {
                const request = JSON.parse(data);
                const { mermaidCode, format = 'png' } = request;
                
                if (!mermaidCode) {
                    console.error('No mermaid code provided in the message');
                    continue;
                }

                const result = await processMermaidCode(mermaidCode, format);
                console.log('Successfully generated diagram:', result.outputFile);

                if (msg.reply) {
                    nc.publish(msg.reply, sc.encode(JSON.stringify({
                        success: true,
                        outputFile: result.outputFile
                    })));
                    console.log('Sent success response');
                }
            } catch (error) {
                console.error('Error processing message:', error);
                if (msg.reply) {
                    nc.publish(msg.reply, sc.encode(JSON.stringify({
                        success: false,
                        error: error.message
                    })));
                    console.log('Sent error response');
                }
            }
        }
    } catch (err) {
        console.error('Fatal error:', err);
        process.exit(1);
    }
}

console.log('Starting main process...');
main().catch(err => {
    console.error('Fatal error in main:', err);
    process.exit(1);
});