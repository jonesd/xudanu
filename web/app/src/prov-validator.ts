export function buildProvValidatorHtml(provJson: string): string {
  const escaped = JSON.stringify(provJson);
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PROV-JSON Validator</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Inter',system-ui,sans-serif;background:#0d1117;color:#c9d1d9;line-height:1.6}
a{color:#58a6ff;text-decoration:none}a:hover{text-decoration:underline}
.wrap{max-width:1100px;margin:0 auto;padding:32px 24px 60px}
h1{font-size:28px;font-weight:800;color:#e6edf3;margin-bottom:4px}
.sub{font-size:14px;color:#8b949e;margin-bottom:24px}
.toolbar{display:flex;gap:12px;margin-bottom:16px;align-items:center;flex-wrap:wrap}
.btn{padding:8px 16px;border-radius:6px;border:1px solid #30363d;background:#21262d;color:#c9d1d9;font-size:13px;font-family:inherit;cursor:pointer}
.btn:hover{border-color:#58a6ff;background:#1c2330}
.btn-go{background:#238636;border-color:#238636;color:#fff;font-weight:600}
.btn-go:hover{background:#2ea043}
.btn-ext{background:none;border:1px solid #a371f744;color:#a371f7}
.two-col{display:grid;grid-template-columns:1fr 1fr;gap:16px;height:460px}
.panel{display:flex;flex-direction:column;background:#161b22;border:1px solid #21262d;border-radius:8px;overflow:hidden}
.ph{padding:8px 12px;border-bottom:1px solid #21262d;display:flex;justify-content:space-between;align-items:center}
.pt{font-size:12px;font-weight:600;color:#8b949e;text-transform:uppercase;letter-spacing:0.5px}
.pbadge{font-size:10px;padding:2px 8px;border-radius:10px;font-weight:600;display:none}
.pbadge.ok{background:rgba(63,185,80,0.15);color:#3fb950;border:1px solid rgba(63,185,80,0.3)}
textarea{flex:1;background:#0d1117;border:none;color:#c9d1d9;font-family:'JetBrains Mono',monospace;font-size:12px;line-height:1.5;padding:12px;resize:none;outline:none;tab-size:2}
textarea:focus{box-shadow:inset 0 0 0 2px #58a6ff33}
.results{margin-top:16px;padding:16px;border-radius:8px;font-size:13px;display:none}
.results.ok{background:rgba(63,185,80,0.08);border:1px solid rgba(63,185,80,0.3);color:#3fb950}
.results.err{background:rgba(248,81,73,0.08);border:1px solid rgba(248,81,73,0.3);color:#f85149}
.results ul{margin:8px 0 0 20px}.results li{margin-bottom:4px;font-family:'JetBrains Mono',monospace;font-size:12px}
.links{margin-top:24px;padding:16px;background:#161b22;border:1px solid #21262d;border-radius:8px}
.links h3{font-size:13px;color:#e6edf3;margin-bottom:8px}.links ul{margin-left:20px}
.links li{margin-bottom:4px;font-size:13px}
.foot{margin-top:32px;padding-top:16px;border-top:1px solid #21262d;font-size:12px;color:#484f58;text-align:center}
@media(max-width:768px){.two-col{grid-template-columns:1fr;height:auto}.panel{height:240px}}
</style>
</head>
<body>
<div class="wrap">
<h1>PROV-JSON Validator</h1>
<p class="sub">W3C PROV-JSON validation. Runs entirely in your browser.</p>
<div class="toolbar">
  <button class="btn btn-go" onclick="doVal()">Validate</button>
  <button class="btn" onclick="dl()">Download JSON</button>
  <a class="btn btn-ext" href="https://openprovenance.org/prov-json/" target="_blank">PROV-JSON Spec</a>
  <a class="btn btn-ext" href="https://openprovenance.org/" target="_blank">Open Provenance</a>
</div>
<div class="two-col">
  <div class="panel"><div class="ph"><span class="pt">PROV-JSON Schema</span></div><textarea id="schema" spellcheck="false"></textarea></div>
  <div class="panel"><div class="ph"><span class="pt">Your Output</span><span class="pbadge" id="badge"></span></div><textarea id="output" spellcheck="false"></textarea></div>
</div>
<div class="results" id="results"></div>
<div class="links">
  <h3>Resources</h3>
  <ul>
    <li><a href="https://openprovenance.org/prov-json/" target="_blank">PROV-JSON Specification (W3C)</a></li>
    <li><a href="https://openprovenance.org/prov-json/schema" target="_blank">Official JSON Schema</a></li>
    <li><a href="https://www.jsonschemavalidator.net/" target="_blank">jsonschemavalidator.net</a></li>
    <li><a href="https://www.w3.org/TR/prov-dm/" target="_blank">PROV Data Model</a></li>
  </ul>
</div>
<div class="foot">No data leaves your browser.</div>
</div>
<script>
var OUTPUT_JSON = ${escaped};
document.getElementById('output').value = OUTPUT_JSON;

var SCHEMA = {"$id": "https://openprovenance.org/prov-json/schema#", "$schema": "http://json-schema.org/draft-04/schema#", "type": "object", "allOf": [{"$ref": "#/definitions/bundle"}, {"properties": {"bundle": {"type": "object", "additionalProperties": {"$ref": "#/definitions/bundle"}}}}], "definitions": {"literal-simple": {"oneOf": [{"type": "string"}, {"type": "boolean"}, {"type": "number"}]}, "literal-typed": {"type": "object", "properties": {"$": {"$ref": "#/definitions/literal-simple"}, "type": {"type": "string"}}, "required": ["$", "type"], "additionalProperties": false}, "literal-international-string": {"type": "object", "properties": {"$": {"type": "string"}, "lang": {"type": "string"}}, "required": ["$", "lang"], "additionalProperties": false}, "literal-complex": {"anyOf": [{"$ref": "#/definitions/literal-typed"}, {"$ref": "#/definitions/literal-international-string"}]}, "literal-single": {"oneOf": [{"$ref": "#/definitions/literal-simple"}, {"$ref": "#/definitions/literal-complex"}]}, "literal-array": {"type": "array", "items": {"$ref": "#/definitions/literal-single"}}, "literal": {"oneOf": [{"$ref": "#/definitions/literal-single"}, {"$ref": "#/definitions/literal-array"}]}, "entity": {"type": "object", "additionalProperties": {"$ref": "#/definitions/literal"}}, "agent": {"$ref": "#/definitions/entity"}, "activity": {"type": "object", "properties": {"prov:startTime": {"type": "string"}, "prov:endTime": {"type": "string"}}, "additionalProperties": {"$ref": "#/definitions/literal"}}, "generation": {"type": "object", "properties": {"prov:entity": {"type": "string"}, "prov:activity": {"type": "string"}, "prov:time": {"type": "string"}}, "required": ["prov:entity"], "additionalProperties": {"$ref": "#/definitions/literal"}}, "usage": {"type": "object", "properties": {"prov:entity": {"type": "string"}, "prov:activity": {"type": "string"}, "prov:time": {"type": "string"}}, "required": ["prov:activity"], "additionalProperties": {"$ref": "#/definitions/literal"}}, "derivation": {"type": "object", "properties": {"prov:generatedEntity": {"type": "string"}, "prov:usedEntity": {"type": "string"}, "prov:activity": {"type": "string"}, "prov:generation": {"type": "string"}, "prov:usage": {"type": "string"}}, "required": ["prov:generatedEntity", "prov:usedEntity"], "additionalProperties": {"$ref": "#/definitions/literal"}}, "attribution": {"type": "object", "properties": {"prov:entity": {"type": "string"}, "prov:agent": {"type": "string"}}, "required": ["prov:entity", "prov:agent"], "additionalProperties": {"$ref": "#/definitions/literal"}}, "association": {"type": "object", "properties": {"prov:activity": {"type": "string"}, "prov:agent": {"type": "string"}, "prov:plan": {"type": "string"}}, "required": ["prov:activity"], "additionalProperties": {"$ref": "#/definitions/literal"}}, "bundle": {"type": "object", "properties": {"prefix": {"type": "object", "patternProperties": {"^[a-zA-Z0-9_\\-]+$": {"type": "string"}}, "additionalProperties": false}, "entity": {"type": "object", "additionalProperties": {"$ref": "#/definitions/entity"}}, "agent": {"type": "object", "additionalProperties": {"$ref": "#/definitions/agent"}}, "activity": {"type": "object", "additionalProperties": {"$ref": "#/definitions/activity"}}, "wasGeneratedBy": {"type": "object", "additionalProperties": {"$ref": "#/definitions/generation"}}, "used": {"type": "object", "additionalProperties": {"$ref": "#/definitions/usage"}}, "wasDerivedFrom": {"type": "object", "additionalProperties": {"$ref": "#/definitions/derivation"}}, "wasAttributedTo": {"type": "object", "additionalProperties": {"$ref": "#/definitions/attribution"}}, "wasAssociatedWith": {"type": "object", "additionalProperties": {"$ref": "#/definitions/association"}}}}}};
document.getElementById('schema').value = JSON.stringify(SCHEMA, null, 2);

function doVal() {
  var errs = [], doc;
  try { doc = JSON.parse(document.getElementById('output').value); }
  catch(e) { show(false, ['JSON parse error: ' + e.message]); return; }
  vp(doc, '', errs);
  show(errs.length === 0, errs);
}

function show(ok, errs) {
  var d = document.getElementById('results'), b = document.getElementById('badge');
  d.style.display = 'block';
  if (ok) {
    d.className = 'results ok';
    d.innerHTML = '<strong>No errors found.</strong> Validates against the PROV-JSON schema.';
    b.style.display = ''; b.textContent = 'Valid'; b.className = 'pbadge ok';
  } else {
    d.className = 'results err';
    d.innerHTML = '<strong>Errors:</strong><ul>' + errs.map(function(e){return '<li>'+esc(e)+'</li>';}).join('') + '</ul>';
    b.style.display = ''; b.textContent = 'Invalid';
    b.style.cssText = 'display:inline-block;background:rgba(248,81,73,0.15);color:#f85149;border:1px solid rgba(248,81,73,0.3);font-size:10px;padding:2px 8px;border-radius:10px;font-weight:600';
  }
}

function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}

function vp(doc, p, errs) {
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) { errs.push(p+': root must be object'); return; }
  if ('bundle' in doc && doc.bundle != null) { if (typeof doc.bundle !== 'object' || Array.isArray(doc.bundle)) errs.push(p+'.bundle: must be object'); }
  if (doc.entity) em(doc.entity, p+'.entity', errs);
  if (doc.agent) em(doc.agent, p+'.agent', errs);
  if (doc.activity) am(doc.activity, p+'.activity', errs);
  if (doc.wasGeneratedBy) rl(doc.wasGeneratedBy, p+'.wasGeneratedBy', ['prov:entity'], errs);
  if (doc.used) rl(doc.used, p+'.used', ['prov:activity'], errs);
  if (doc.wasAttributedTo) rl(doc.wasAttributedTo, p+'.wasAttributedTo', ['prov:entity','prov:agent'], errs);
  if (doc.wasAssociatedWith) rl(doc.wasAssociatedWith, p+'.wasAssociatedWith', ['prov:activity'], errs);
  if (doc.wasDerivedFrom) rl(doc.wasDerivedFrom, p+'.wasDerivedFrom', ['prov:generatedEntity','prov:usedEntity'], errs);
}

function em(m, p, errs) {
  for (var id in m) { var e = m[id]; if (typeof e !== 'object' || e === null) { errs.push(p+'.'+id+': must be object'); continue; } for (var a in e) vl(e[a], p+'.'+id+'.'+a, errs); }
}

function am(m, p, errs) {
  for (var id in m) { var a = m[id]; if (typeof a !== 'object' || a === null) { errs.push(p+'.'+id+': must be object'); continue; }
    if ('prov:startTime' in a && typeof a['prov:startTime'] !== 'string') errs.push(p+'.'+id+'.startTime: must be string');
    if ('prov:endTime' in a && typeof a['prov:endTime'] !== 'string') errs.push(p+'.'+id+'.endTime: must be string');
    for (var k in a) { if (k === 'prov:startTime' || k === 'prov:endTime') continue; vl(a[k], p+'.'+id+'.'+k, errs); }
  }
}

function rl(m, p, req, errs) {
  for (var id in m) { var r = m[id]; if (typeof r !== 'object' || r === null) { errs.push(p+'.'+id+': must be object'); continue; }
    for (var i=0;i<req.length;i++) { if (!(req[i] in r)) errs.push(p+'.'+id+': missing "'+req[i]+'"'); else if (typeof r[req[i]] !== 'string') errs.push(p+'.'+id+'.'+req[i]+': must be string'); }
    for (var k in r) { if (req.indexOf(k) >= 0) continue; vl(r[k], p+'.'+id+'.'+k, errs); }
  }
}

function vl(v, p, errs) {
  if (v === null) { errs.push(p+': must not be null'); return; }
  if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') return;
  if (Array.isArray(v)) { for (var i=0;i<v.length;i++) vl(v[i], p+'['+i+']', errs); return; }
  if (typeof v === 'object') {
    if (!('$' in v)) { errs.push(p+': literal needs "$"'); return; }
    if (!('type' in v) && !('lang' in v)) { errs.push(p+': literal needs "type" or "lang"'); return; }
    for (var k in v) if (k !== '$' && k !== 'type' && k !== 'lang') errs.push(p+': unexpected "'+k+'"');
  }
}

function dl() {
  var blob = new Blob([document.getElementById('output').value], {type: 'application/json'});
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url; a.download = 'prov-json-' + Date.now() + '.json';
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

window.onload = function() { setTimeout(doVal, 100); };
</script>
</body></html>`;
}
