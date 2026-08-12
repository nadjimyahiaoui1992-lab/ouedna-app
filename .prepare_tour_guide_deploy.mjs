import fs from 'node:fs';
const code = fs.readFileSync('/home/ubuntu/souf-tour/supabase/functions/tour-guide/index.ts', 'utf8');
const payload = {
  project_id: 'cwbenhuiextfoiyfboxo',
  name: 'tour-guide',
  verify_jwt: false,
  entrypoint_path: 'index.ts',
  files: [
    { name: 'index.ts', content: code }
  ]
};
fs.writeFileSync('/home/ubuntu/souf-tour/.tmp_deploy_payload.json', JSON.stringify(payload));
console.log('Payload ready');
