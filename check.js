const fs = require('fs');
const text = fs.readFileSync('lib/pages/new_pages/user_profile/user_profile_widget.dart', 'utf8');

const stack = [];
for (let i = 0; i < text.length; i++) {
    const c = text[i];
    // skip string literals
    if (c === "'") {
        i++;
        while (i < text.length && text[i] !== "'") {
            if (text[i] === '\\') i++;
            i++;
        }
        continue;
    }
    if (c === '"') {
        i++;
        while (i < text.length && text[i] !== '"') {
            if (text[i] === '\\') i++;
            i++;
        }
        continue;
    }
    
    // skip line comments
    if (c === '/' && text[i+1] === '/') {
        i += 2;
        while (i < text.length && text[i] !== '\n') i++;
        continue;
    }
    
    // skip block comments
    if (c === '/' && text[i+1] === '*') {
        i += 2;
        while (i < text.length && !(text[i] === '*' && text[i+1] === '/')) i++;
        i++;
        continue;
    }

    if ('{[(<'.includes(c)) {
        if (c === '<') {
            // Very naive check for generics vs less than
            if (text.substr(i-10, 10).includes('Stream') || text.substr(i-10, 10).includes('List') || text.substr(i-10, 10).includes('Map') || text.substr(i-10, 10).includes('Set') || text.substr(i-10, 10).includes('Future')) {
                stack.push({ c, line: text.substr(0, i).split('\n').length });
            }
        } else {
            stack.push({ c, line: text.substr(0, i).split('\n').length });
        }
    } else if ('}])>'.includes(c)) {
        if (c === '>') {
            if (stack.length && stack[stack.length - 1].c === '<') {
                stack.pop();
            }
            continue;
        }

        if (stack.length === 0) {
            console.log(`Unmatched closing ${c} at line ${text.substr(0, i).split('\n').length}`);
            process.exit(1);
        }
        const top = stack.pop();
        if ((top.c === '{' && c !== '}') ||
            (top.c === '[' && c !== ']') ||
            (top.c === '(' && c !== ')')) {
            console.log(`Mismatch! Expected match for ${top.c} from line ${top.line}, but found ${c} at line ${text.substr(0, i).split('\n').length}`);
            process.exit(1);
        }
    }
}

if (stack.length > 0) {
    console.log(`Unclosed ${stack[stack.length - 1].c} from line ${stack[stack.length - 1].line}`);
    process.exit(1);
}

console.log("All brackets match!");
