let props = [];
let selectedId = null;

window.addEventListener('message', ({ data }) => {
    if (data.action === 'openPanel') {
        document.getElementById('panel').classList.remove('hidden');
        props = data.props || [];
        renderProps();
    }
});

document.getElementById('closeBtn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closePanel`, { method: 'POST', body: JSON.stringify({}) });
    document.getElementById('panel').classList.add('hidden');
});

function renderProps() {
    const list = document.getElementById('propList');
    list.innerHTML = '';
    props.forEach(p => {
        const div = document.createElement('div');
        div.className = 'prop-item' + (p.id === selectedId ? ' active' : '');
        div.textContent = `${p.label} (Stage: ${p.stage})`;
        div.onclick = () => selectProp(p);
        list.appendChild(div);
    });
}

function selectProp(p) {
    selectedId = p.id;
    document.getElementById('editSection').style.display = 'block';
    document.getElementById('editLabel').textContent = p.label;
    document.getElementById('stageSelect').value = p.stage;
    document.getElementById('coordX').value = p.coords.x.toFixed(2);
    document.getElementById('coordY').value = p.coords.y.toFixed(2);
    document.getElementById('coordZ').value = p.coords.z.toFixed(2);
    document.getElementById('heading').value = p.heading.toFixed(1);
    renderProps();
}

function send(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        body: JSON.stringify(data),
    });
}

document.getElementById('applyStage').addEventListener('click', () => {
    send('setStage', { id: selectedId, stage: parseInt(document.getElementById('stageSelect').value) });
});

document.getElementById('applyMove').addEventListener('click', () => {
    send('moveProp', {
        id: selectedId,
        x: parseFloat(document.getElementById('coordX').value),
        y: parseFloat(document.getElementById('coordY').value),
        z: parseFloat(document.getElementById('coordZ').value),
        heading: parseFloat(document.getElementById('heading').value),
    });
});

document.getElementById('deleteBtn').addEventListener('click', () => {
    send('deleteProp', { id: selectedId });
    selectedId = null;
    document.getElementById('editSection').style.display = 'none';
    renderProps();
});   