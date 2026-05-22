const fs = require('fs');
const path = require('path');

const dataFile = path.join('b:', 'DEV', 'KADRO', 'master_data.json');
const part1File = path.join('b:', 'DEV', 'KADRO', 'master_template_part1.txt');
const part2File = path.join('b:', 'DEV', 'KADRO', 'master_template_part2.txt');
const outputFile = path.join('b:', 'DEV', 'KADRO', 'kadro_master_roster.html');

const all = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
const part1 = fs.readFileSync(part1File, 'utf8');
const part2 = fs.readFileSync(part2File, 'utf8');

let updatedPart2 = part2;

// 1. Update Avatar to use vesikalik_path
updatedPart2 = updatedPart2.replace(
  '<div class=\'avatar\'>${initials}</div>',
  `<div class='avatar' style='background-image: url(\${p.vesikalik_path}); background-size: cover; background-position: center; border: 1px solid var(--border);'>\${p.vesikalik_path ? "" : initials}</div>`
);

// 2. Add CV Link next to name
updatedPart2 = updatedPart2.replace(
  '<div class=\'name\'>${p.flag || \'\'} ${p.name}</div>',
  `<div class='name' style='display:flex; justify-content:space-between; align-items:center;'><span>\${p.flag || ''} \${p.name}</span><a href="\${p.cv_path}" target='_blank' class='copy-btn' style='float:none; text-decoration:none; font-size: 0.65rem; padding: 2px 6px;'>CV</a></div>`
);

// 3. Add Full Body Preview
updatedPart2 = updatedPart2.replace(
  '<div class=\'prompt-section\'>',
  `<div class='body-preview' style='border-top: 1px solid var(--border); height: 180px; overflow:hidden; position:relative; background:var(--bg);'><img src="\${p.boydan_path}" style='width:100%; position:absolute; top:-10%; left:0; opacity:0.6; transition: opacity 0.3s;' onmouseover='this.style.opacity=1' onmouseout='this.style.opacity=0.6'><div style='position:absolute; bottom:0; left:0; right:0; background:linear-gradient(transparent, var(--surface)); height:40px;'></div></div><div class='prompt-section'>`
);

fs.writeFileSync(outputFile, part1 + JSON.stringify(all) + ';' + updatedPart2, 'utf8');
console.log('Build complete: kadro_master_roster.html updated.');
