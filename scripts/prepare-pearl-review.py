"""Build an isolated browser review for both V6 themes from the existing harness.

Build release Web with the existing public client config first, then:
  python scripts/prepare-pearl-review.py
  $env:QA_SNAPSHOT='1'; $env:QA_WIDTH='390'; $env:QA_THEME='light'
  node build/review-pearl.mjs

Repeat at 1280 and with QA_THEME=dark. QA_THEME_FLOW=1 additionally checks
theme switching during actual synthetic audio and persistence after refresh.
The harness uses only an isolated PostgreSQL fixture, generated JWT test keys,
synthetic media, intercepted Clerk and an owned headless Chrome profile.
"""
from pathlib import Path
import runpy

runpy.run_path('scripts/prepare-obsidian-review.py')
source = Path('build/review-obsidian.mjs').read_text(encoding='utf-8')
source = source.replace('build/obsidian-review', 'build/aurora-pearl-review')
source = source.replace('const output = path.join(root, "build/aurora-pearl-review");', '''const theme = process.env.QA_THEME === 'dark' ? 'dark' : 'light';
const output = path.join(root, "build/aurora-pearl-review", theme, process.env.QA_ONLY_FLOW ? 'flow' : '');''')
source = source.replace('source: `window.__qaAudio=[];', '''source: `if(location.origin === 'http://localhost:3000' && !localStorage.getItem('soundshare.themeMode')) localStorage.setItem('soundshare.themeMode', JSON.stringify('${theme}')); window.__qaAudio=[];''')
source = source.replace("'[role=\"button\"],button'", "'[role=\"button\"],[role=\"switch\"],[role=\"checkbox\"],button'")
source = source.replace('  assert.deepEqual(report.apiFailures, []);', '''
  if (process.env.QA_THEME_FLOW) {
    await navigate('/');
    await click('Nghe ngay');
    await sleep(1200);
    const before = await evaluate("({route:location.hash,session:Clerk.session.id,audio:window.__qaAudio.length,position:window.__qaAudio.at(-1).currentTime})");
    const next = theme === 'light' ? 'dark' : 'light';
    await click('Giao diện tối');
    assert.equal(await evaluate('document.documentElement.dataset.theme'), next);
    const after = await evaluate("({route:location.hash,session:Clerk.session.id,audio:window.__qaAudio.length,position:window.__qaAudio.at(-1).currentTime,paused:window.__qaAudio.at(-1).paused,stored:JSON.parse(localStorage.getItem('soundshare.themeMode'))})");
    assert.equal(after.route, before.route);
    assert.equal(after.session, before.session);
    assert.equal(after.audio, before.audio);
    assert.equal(after.paused, false);
    assert.ok(after.position >= before.position);
    assert.equal(after.stored, next);
    report.checks.push('Theme changes retain the same HTML audio, playing position, active session and route');
    await send('Page.reload', {ignoreCache:true});
    await sleep(5000);
    await semantics();
    assert.equal(await evaluate('document.documentElement.dataset.theme'), next);
    assert.equal(await evaluate('JSON.parse(localStorage.getItem("soundshare.themeMode"))'), next);
    await click('Theo hệ thống');
    await send('Emulation.setEmulatedMedia', {features:[{name:'prefers-color-scheme',value:'dark'}]});
    await sleep(600);
    assert.equal(await evaluate('document.documentElement.dataset.theme'), 'dark');
    await send('Emulation.setEmulatedMedia', {features:[{name:'prefers-color-scheme',value:'light'}]});
    await sleep(600);
    assert.equal(await evaluate('document.documentElement.dataset.theme'), 'light');
    report.checks.push('F5 restores the preference; System mode responds to live OS brightness');
  }
  assert.deepEqual(report.apiFailures, []);''')
Path('build/review-pearl.mjs').write_text(source, encoding='utf-8')
print('Prepared build/review-pearl.mjs (isolated fixtures only).')

# Separate read-only review of the actual SDK forms. It never enters credentials.
auth = Path('scripts/review-auth-v5.mjs').read_text(encoding='utf-8')
auth = auth.replace("const output = path.join(root, process.env.QA_BEFORE ? 'build/auth-v5-before' : process.env.QA_INTERACTIONS ? 'build/auth-v5-interactions' : 'build/auth-v5-review');", "const theme = process.env.QA_THEME === 'dark' ? 'dark' : 'light';\nconst output = path.join(root, 'build/aurora-pearl-auth', theme);")
auth = auth.replace("const widths = process.env.QA_WIDTH ? [Number(process.env.QA_WIDTH)] : [320,390,430,768,1024,1280,1440];", "const widths = process.env.QA_WIDTH ? [Number(process.env.QA_WIDTH)] : [390,1280];")
auth = auth.replace('source: `sessionStorage.setItem(', "source: `localStorage.setItem('soundshare.themeMode',JSON.stringify('${theme}'));sessionStorage.setItem(")
auth = auth.replace('      report.checks.push({ width, mode, ...bounds });', '''
      if (mode === 'sign-in') {
        const original = await evaluate("(()=>{window.__qaField=document.querySelector('#clerk-auth input');return getComputedStyle(window.__qaField).backgroundColor;})()");
        await evaluate("document.getElementById('auth-theme').click();true");
        await sleep(250);
        const changed = await evaluate("({same:window.__qaField===document.querySelector('#clerk-auth input'),color:getComputedStyle(window.__qaField).backgroundColor})");
        assert.equal(changed.same, true, 'Theme changes keep the mounted Clerk input');
        assert.notEqual(changed.color, original, 'Mounted Clerk input follows theme variables');
        await evaluate(`soundshareTheme.chooseMode('${theme}');true`);
      }
      report.checks.push({ width, mode, ...bounds });''')
Path('build/review-pearl-auth.mjs').write_text(auth, encoding='utf-8')
print('Prepared build/review-pearl-auth.mjs (actual Clerk UI, read-only).')
