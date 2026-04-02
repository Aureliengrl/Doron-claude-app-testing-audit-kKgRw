const fs = require('fs');
const path = require('path');

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            let modified = false;

            // Fix double éé corruption
            if (content.includes('éé')) {
                content = content.split('éé').join('');
                modified = true;
            }

            // Fix corrupted Euro symbol at the end of string interpolations
            if (content.includes('}é\'')) {
                content = content.split('}é\'').join('}€\'');
                modified = true;
            }
            if (content.includes('}é"')) {
                content = content.split('}é"').join('}€"');
                modified = true;
            }

            // Also check for }é which isn't at the end of string
            if (content.includes('}é ')) {
                content = content.split('}é ').join('}€ ');
                modified = true;
            }

            if (modified) {
                fs.writeFileSync(fullPath, content, 'utf8');
                console.log('Fixed ' + fullPath);
            }
        }
    }
}

processDir('lib');
