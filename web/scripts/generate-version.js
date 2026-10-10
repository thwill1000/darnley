import fs from 'fs';
import pkg from '../package.json' with { type: 'json' };

const time = new Date().toISOString().replace('T', ' ').substring(0, 16) + ' UTC';
const content = `export const APP_VERSION = "${pkg.version}";\n`;

fs.writeFileSync('src/version.js', content);
console.log(`Generated web/version.js for v${pkg.version}`);
