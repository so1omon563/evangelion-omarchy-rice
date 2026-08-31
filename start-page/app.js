const $ = id => document.getElementById(id);
let currentData = null;
let densityIndex = 1;

function clock() {
  const date = new Date();
  $('time').textContent = date.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit', hour12: false});
  $('seconds').textContent = date.getSeconds().toString().padStart(2, '0');
  $('minute-ring').style.setProperty('--minute', `${date.getSeconds() * 6}deg`);
  $('date').textContent = date.toLocaleDateString([], {weekday: 'long', year: 'numeric', month: 'long', day: '2-digit'}).toUpperCase();
  if (currentData?.media.status.toLowerCase() === 'playing') {
    currentData.media.position = Math.min(currentData.media.length || Infinity, currentData.media.position + 1);
    paintMedia(currentData.media);
  }
}

function formatTime(seconds) {
  const safe = Number.isFinite(seconds) ? Math.max(0, seconds) : 0;
  return `${Math.floor(safe / 60).toString().padStart(2, '0')}:${Math.floor(safe % 60).toString().padStart(2, '0')}`;
}

function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor(seconds % 86400 / 3600);
  const minutes = Math.floor(seconds % 3600 / 60);
  return days ? `${days}D ${hours.toString().padStart(2, '0')}H` : `${hours.toString().padStart(2, '0')}H ${minutes.toString().padStart(2, '0')}M`;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, character => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[character]));
}

function paintWeather(weather) {
  const parts = weather.message.split('·').map(part => part.trim());
  const state = !weather.available ? 'offline' : weather.stale ? 'stale' : 'live';
  $('weather-card').className = `weather-card ${state}`;
  $('weather').textContent = weather.message.toUpperCase();
  $('weather-place').textContent = weather.available ? (parts[0] || 'LOCAL SECTOR').toUpperCase() : 'LINK OFFLINE';
  $('weather-temp').textContent = weather.available ? (parts[1] || 'Temp --°').replace(/^Temp\s*/i, '') : '--°';
  $('weather-wind').textContent = weather.available ? `WIND // ${(parts[2] || '—').replace(/^Wind\s*/i, '')}` : 'SIGNAL // LOST';
  $('weather-chip').textContent = !weather.available ? 'OFFLINE' : weather.stale ? 'CACHE' : 'LIVE';
  $('weather-state').textContent = weather.available ? weather.stale ? 'LAST KNOWN READING · UPLINK DEGRADED' : 'SATELLITE FEED · 30 SECOND REFRESH' : 'SET LOCATION WITH OMARCHY WEATHER LOCATION';
}

function health(data) {
  const batteryOkay = data.battery == null || data.battery > 10;
  const thermalOkay = !data.thermal.available || !['critical', 'emergency'].includes(data.thermal.tier);
  return [batteryOkay, thermalOkay, data.network.online];
}

function paintMagi(data) {
  const votes = health(data);
  const count = votes.filter(Boolean).length;
  const state = count === 3 ? 'nominal' : count === 2 ? 'warning' : 'critical';
  $('magi-card').className = `hero magi-card ${state}`;
  $('magi-chip').textContent = count === 3 ? 'UNANIMOUS' : `${count}/3 ACCEPT`;
  $('magi-verdict').textContent = count === 3 ? 'ALL SYSTEMS NOMINAL' : count === 2 ? 'CONDITIONAL OPERATION' : 'SYSTEM INTERVENTION';
  $('magi-percent').textContent = `${Math.round(count / 3 * 100).toString().padStart(3, '0')}%`;
  [$('magi-1'), $('magi-2'), $('magi-3')].forEach((node, index) => node.textContent = votes[index] ? 'ACCEPT' : 'REJECT');
  document.querySelectorAll('.magi > div').forEach((node, index) => node.classList.toggle('reject', !votes[index]));
}

function paintTelemetry(data) {
  const battery = data.battery == null ? 0 : data.battery;
  const temperature = data.thermal.available ? data.thermal.temperature_c : 0;
  $('battery').textContent = data.battery == null ? 'N/A' : `${data.battery}%`;
  $('battery-meter').style.width = `${battery}%`;
  $('thermal').textContent = data.thermal.available ? `${temperature}°C` : 'N/A';
  $('thermal-meter').style.width = `${Math.min(100, temperature)}%`;
  $('network').textContent = data.network.online ? data.network.interface.toUpperCase() : 'OFFLINE';
  $('network-signal').classList.toggle('offline', !data.network.online);
  const warning = !health(data).every(Boolean);
  $('telemetry-card').className = `telemetry-card ${warning ? 'warning' : 'nominal'}`;
  $('system-chip').textContent = warning ? 'WARN' : 'NOMINAL';
  $('system-state').textContent = warning ? 'ATTENTION REQUIRED' : 'BUS STABLE';
}

function paintMedia(media) {
  const playing = media.available && media.status.toLowerCase() === 'playing';
  $('audio-card').className = `audio-card ${playing ? 'playing' : media.available ? 'paused' : 'standby'}`;
  $('track').textContent = media.available ? media.title || 'UNTITLED' : 'NO ACTIVE SOURCE';
  $('artist').textContent = media.available ? media.artist || media.status : 'MPRIS STANDBY';
  $('audio-chip').textContent = playing ? 'PLAYING' : media.available ? media.status.toUpperCase() : 'STANDBY';
  $('media-toggle').textContent = playing ? 'Ⅱ' : '▶';
  const progress = media.length > 0 ? Math.min(100, media.position / media.length * 100) : 0;
  $('media-progress').style.width = `${progress}%`;
  $('media-time').textContent = `${formatTime(media.position)} / ${formatTime(media.length)}`;
  $('media-player').textContent = `CHANNEL // ${(media.player || 'NONE').toUpperCase()}`;
  $('media-volume').textContent = String(media.volume || 0).padStart(2, '0');
  $('player-cycle').disabled = !media.players?.length;
}

function paintRail(data) {
  const affinity = data.affinity.active || 'neutral';
  document.body.dataset.affinity = affinity;
  $('rail-affinity').textContent = affinity.replaceAll('-', ' ').toUpperCase();
  $('rail-workspace').textContent = `${data.workspace.id || '—'} // ${data.workspace.name.toUpperCase()}`;
  $('rail-profile').textContent = data.profile.toUpperCase();
  $('rail-uptime').textContent = formatUptime(data.uptime);
  $('rail-network').textContent = data.network.online ? 'CONNECTED' : 'OFFLINE';
}

function paintEvents(events) {
  $('event-log').innerHTML = events.map(event => `<div><time>${escapeHtml(event.time)}</time><b>${escapeHtml(event.type)}</b><span>${escapeHtml(event.message)}</span></div>`).join('');
}

function paintAlert(data) {
  const failed = health(data).map((okay, index) => !okay ? ['BATTERY CAPACITY CRITICAL', 'THERMAL LIMIT EXCEEDED', 'NETWORK UPLINK LOST'][index] : '').filter(Boolean);
  document.body.classList.toggle('alert', failed.length > 0);
  $('alert-copy').textContent = failed.join(' // ') || 'SYSTEM ANOMALY DETECTED';
}

async function sync() {
  try {
    const data = await fetch('/api/status').then(response => response.json());
    currentData = data;
    const map = {background: 'bg', dark_background: 'dark', foreground: 'fg', dark_foreground: 'muted', bright_red: 'red'};
    Object.entries(data.theme).forEach(([key, value]) => document.documentElement.style.setProperty(`--${map[key] || key}`, value));
    paintMagi(data); paintTelemetry(data); paintMedia(data.media); paintWeather(data.weather); paintRail(data); paintEvents(data.events); paintAlert(data);
    $('sync').textContent = 'SYNCHRONIZED';
  } catch (error) {
    $('sync').textContent = 'LOCAL DATA UNAVAILABLE';
  }
}

async function mediaAction(action) {
  await fetch(`/api/media/${action}`, {method: 'POST'});
  setTimeout(sync, 250);
}

function cycleDensity() {
  const modes = ['compact', 'standard', 'command'];
  densityIndex = (densityIndex + 1) % modes.length;
  document.body.dataset.density = modes[densityIndex];
  $('density-toggle').textContent = `DENSITY // ${modes[densityIndex].slice(0, 3).toUpperCase()}`;
  localStorage.setItem('nerv-density', modes[densityIndex]);
}

const paletteCommands = [
  {name: 'OPEN GITHUB', hint: 'EXTERNAL LINK', run: () => location.href = 'https://github.com'},
  {name: 'OPEN LINEAR', hint: 'EXTERNAL LINK', run: () => location.href = 'https://linear.app'},
  {name: 'OPEN MAIL', hint: 'EXTERNAL LINK', run: () => location.href = 'https://mail.google.com'},
  {name: 'MEDIA PLAY / PAUSE', hint: 'MPRIS', run: () => mediaAction('toggle')},
  {name: 'MEDIA PREVIOUS', hint: 'MPRIS', run: () => mediaAction('previous')},
  {name: 'MEDIA NEXT', hint: 'MPRIS', run: () => mediaAction('next')},
  {name: 'CYCLE DISPLAY DENSITY', hint: 'LOCAL UI', run: cycleDensity},
  {name: 'REFRESH TELEMETRY', hint: 'LOCAL API', run: sync},
];
let paletteSelection = 0;

function renderPalette() {
  const query = $('palette-input').value.toUpperCase();
  const commands = paletteCommands.filter(command => command.name.includes(query));
  paletteSelection = Math.min(paletteSelection, Math.max(0, commands.length - 1));
  $('palette-results').innerHTML = commands.map((command, index) => `<button class="${index === paletteSelection ? 'selected' : ''}" data-command="${paletteCommands.indexOf(command)}"><b>${command.name}</b><span>${command.hint}</span></button>`).join('') || '<p>NO MATCHING COMMAND</p>';
}

function openPalette() { $('command-palette').hidden = false; paletteSelection = 0; $('palette-input').value = ''; renderPalette(); $('palette-input').focus(); }
function closePalette() { $('command-palette').hidden = true; }

document.querySelectorAll('[data-media]').forEach(button => button.addEventListener('click', () => mediaAction(button.dataset.media)));
$('player-cycle').addEventListener('click', async () => {
  const players = currentData?.media.players || [];
  if (!players.length) return;
  const active = players.findIndex(player => player.startsWith(currentData.media.player));
  const player = players[(active + 1) % players.length];
  await fetch('/api/media/player', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({player})});
  setTimeout(sync, 200);
});
$('density-toggle').addEventListener('click', cycleDensity);
$('palette-close').addEventListener('click', closePalette);
$('palette-input').addEventListener('input', () => { paletteSelection = 0; renderPalette(); });
$('palette-results').addEventListener('click', event => { const button = event.target.closest('[data-command]'); if (button) { paletteCommands[button.dataset.command].run(); closePalette(); } });
document.addEventListener('keydown', event => {
  if (event.key === '/' && $('command-palette').hidden && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) { event.preventDefault(); openPalette(); return; }
  if ($('command-palette').hidden) return;
  if (event.key === 'Escape') closePalette();
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') { event.preventDefault(); paletteSelection += event.key === 'ArrowDown' ? 1 : -1; paletteSelection = Math.max(0, paletteSelection); renderPalette(); }
  if (event.key === 'Enter') { const selected = $('palette-results').querySelector('.selected'); if (selected) { paletteCommands[selected.dataset.command].run(); closePalette(); } }
});
document.addEventListener('pointermove', event => {
  document.documentElement.style.setProperty('--pointer-x', `${event.clientX / innerWidth * 100}%`);
  document.documentElement.style.setProperty('--pointer-y', `${event.clientY / innerHeight * 100}%`);
});

const savedDensity = localStorage.getItem('nerv-density');
if (['compact', 'standard', 'command'].includes(savedDensity)) { densityIndex = ['compact', 'standard', 'command'].indexOf(savedDensity); document.body.dataset.density = savedDensity; $('density-toggle').textContent = `DENSITY // ${savedDensity.slice(0, 3).toUpperCase()}`; }
clock(); sync(); setInterval(clock, 1000); setInterval(sync, 30000);
setTimeout(() => $('boot-copy').textContent = 'CONNECTING TELEMETRY BUS', 450);
setTimeout(() => $('boot-copy').textContent = 'MAGI CONSENSUS CONFIRMED', 950);
setTimeout(() => $('boot-sequence').classList.add('complete'), 1450);
setTimeout(() => $('boot-sequence').remove(), 2200);
