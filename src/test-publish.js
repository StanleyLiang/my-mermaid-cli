const { connect, StringCodec } = require('nats');

const sc = StringCodec();
const natsUrl = 'nats://nats:4222';  // 使用固定的服務名稱，因為我們使用 Docker 網絡

async function publishTest() {
    try {
        console.log('Connecting to NATS:', natsUrl);
        const nc = await connect({ 
            servers: natsUrl,
            timeout: 3000 // 增加超時時間
        });
        console.log('Connected to NATS');

        const testMessage = {
            mermaidCode: 'graph TD\nA[開始] --> B[測試]\nB --> C[結束]',
            format: 'png'
        };

        console.log('Publishing message:', JSON.stringify(testMessage));
        nc.publish('mermaid.render', sc.encode(JSON.stringify(testMessage)));
        console.log('Published test message');
        
        // Wait a moment before closing
        await new Promise(resolve => setTimeout(resolve, 1000));
        await nc.close();
        console.log('Connection closed');
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
}

console.log('Starting test publisher...');
publishTest();