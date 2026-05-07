<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cabana Booking by Gulzada</title>

<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>

<style>

body{
    font-family:'Inter',sans-serif;
    background:#F4F3EF;
    margin:0;
    padding:20px;
    color:#333;
}

h1{
    text-align:center;
    color:#677D73;
    margin-bottom:20px;
}

.section{
    background:white;
    padding:15px;
    border-radius:25px;
    margin-bottom:15px;
    box-shadow:0 4px 10px rgba(0,0,0,0.08);
}

.section h2{
    margin:0;
    color:#677D73;
    cursor:pointer;
}

.content{
    display:none;
    margin-top:15px;
}

.grid{
    display:grid;
    grid-template-columns:repeat(auto-fill,minmax(120px,1fr));
    gap:10px;
}

.cell{
    padding:10px;
    border-radius:20px;
    text-align:center;
    font-size:14px;
    transition:0.2s;
}

.cell:hover{
    transform:scale(1.03);
}

.status-free{
    background:#A7CFA5;
}

.status-booked{
    background:#E26D6D;
}

.status-complimentary{
    background:#E8D27C;
}

.status-event{
    background:#7DAAE3;
}

.emoji{
    display:block;
    font-size:20px;
    margin-bottom:5px;
}

button{
    border:none;
    border-radius:20px;
    padding:10px 15px;
    cursor:pointer;
    background:#677D73;
    color:white;
    margin:5px;
}

.clear-btn{
    background:#E26D6D;
}

.color-circle{
    display:inline-block;
    width:14px;
    height:14px;
    border-radius:50%;
    margin-right:8px;
}

.modal{
    display:none;
    position:fixed;
    top:0;
    left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.4);
    justify-content:center;
    align-items:center;
    z-index:1000;
}

.modal-content{
    background:white;
    padding:20px;
    border-radius:15px;
    width:320px;
}

input,select,textarea{
    width:100%;
    margin-top:5px;
    margin-bottom:10px;
    padding:8px;
    border-radius:10px;
    border:1px solid #ccc;
    box-sizing:border-box;
}

textarea{
    resize:vertical;
}

.pdf-buttons{
    margin-bottom:20px;
    text-align:center;
}

</style>
</head>

<body>

<h1>Cabana Booking by Gulzada</h1>

<!-- PDF Buttons -->

<div class="pdf-buttons">

<button onclick="saveSectionPDF('Escape')">
📄 Escape PDF
</button>

<button onclick="saveSectionPDF('Lotus')">
📄 Lotus PDF
</button>

<button onclick="saveSectionPDF('Joystone')">
📄 Joystone PDF
</button>

</div>

<!-- Information -->

<div class="section" id="info">

<h2 onclick="toggle('infoContent')">
ℹ️ Information
</h2>

<div class="content" id="infoContent">

<h3>Colors</h3>

<p>
<span class="color-circle" style="background:#A7CFA5;"></span>
Free / Boş
</p>

<p>
<span class="color-circle" style="background:#E26D6D;"></span>
Booked / Rezerve
</p>

<p>
<span class="color-circle" style="background:#E8D27C;"></span>
Complimentary / İkram
</p>

<p>
<span class="color-circle" style="background:#7DAAE3;"></span>
Event / Etkinlik
</p>

<h3>Stickers</h3>

<p>♿ Wheelchair</p>
<p>🌶️ Spicy Allergy</p>
<p>🤧 Allergy</p>
<p>🔇 Likes Silence</p>
<p>🚭 Non-smoker</p>
<p>👶 Kids</p>
<p>💍 Honeymoon</p>
<p>🎂 Birthday</p>
<p>⭐ VIP</p>
<p>🧼 Cleaning</p>
<p>💌 Special Request</p>
<p>👵 Elderly Guest</p>

</div>
</div>

<!-- Sections -->

<div id="cabanaSections"></div>

<!-- Modal -->

<div class="modal" id="modal">

<div class="modal-content">

<h3>Edit Cabana</h3>

<label>Room Number</label>
<input type="text" id="modalRoom">

<label>Sold By</label>
<input type="text" id="modalSold">

<label>Status</label>

<select id="modalStatus">
<option value="free">Free</option>
<option value="booked">Booked</option>
<option value="complimentary">Complimentary</option>
<option value="event">Event</option>
</select>

<label>Meal</label>

<select id="modalMeal">
<option value="BB">BB</option>
<option value="All Inclusive">All Inclusive</option>
</select>

<label>Emoji</label>

<select id="modalEmoji">
<option value="">None</option>
<option value="♿">♿</option>
<option value="🌶️">🌶️</option>
<option value="🤧">🤧</option>
<option value="🔇">🔇</option>
<option value="🚭">🚭</option>
<option value="👶">👶</option>
<option value="💍">💍</option>
<option value="🎂">🎂</option>
<option value="⭐">⭐</option>
<option value="🧼">🧼</option>
<option value="💌">💌</option>
<option value="👵">👵</option>
</select>

<label>Notes</label>

<textarea id="modalNotes" rows="4"></textarea>

<button onclick="saveCell()">
Save
</button>

</div>
</div>

<script>

// Sections
const cabanasData = [

    {name:'Escape',count:21},

    {name:'Lotus',count:8},

    {name:'Joystone',count:18}
];

// Storage
let cabanas = JSON.parse(
    localStorage.getItem('cabanas')
) || {};

// Create Empty Data
cabanasData.forEach(sec=>{

    if(!cabanas[sec.name]){

        cabanas[sec.name]=[];

        for(let i=1;i<=sec.count;i++){

            cabanas[sec.name].push({

                room:'',
                sold:'',
                status:'free',
                meal:'BB',
                emoji:'',
                notes:''
            });
        }
    }
});

// Toggle
function toggle(id){

    const el=document.getElementById(id);

    el.style.display=
    el.style.display==='block'
    ? 'none'
    : 'block';
}

// Render Sections
const cabanaSections=
document.getElementById('cabanaSections');

cabanasData.forEach(sec=>{

    const section=document.createElement('div');

    section.className='section';

    section.innerHTML=`

        <h2 onclick="toggle('${sec.name}')">
        🏝️ ${sec.name}
        </h2>

        <div class="content" id="${sec.name}">

            <button class="clear-btn"
            onclick="clearSection('${sec.name}')">

            Очистить

            </button>

            <div class="grid"></div>

        </div>
    `;

    cabanaSections.appendChild(section);

    renderGrid(sec.name);
});

// Render Grid
function renderGrid(secName){

    const grid=
    document.getElementById(secName)
    .querySelector('.grid');

    grid.innerHTML='';

    cabanas[secName].forEach((c,i)=>{

        const cell=document.createElement('div');

        cell.className=
        'cell status-'+c.status;

        cell.innerHTML=`

            <span class="emoji">
            ${c.emoji || ''}
            </span>

            <strong>
            ${secName} ${i+1}
            </strong>

            <br><br>

            Room:
            ${c.room || '-'}

            <br>

            Sold:
            ${c.sold || '-'}

            <br>

            <strong>
            ${c.meal || ''}
            </strong>

        `;

        cell.onclick=()=>openModal(secName,i);

        grid.appendChild(cell);
    });
}

// Modal
let currentSec;
let currentIndex;

function openModal(sec,i){

    currentSec=sec;
    currentIndex=i;

    const c=cabanas[sec][i];

    document.getElementById('modalRoom').value=c.room;

    document.getElementById('modalSold').value=c.sold;

    document.getElementById('modalStatus').value=c.status;

    document.getElementById('modalMeal').value=c.meal;

    document.getElementById('modalEmoji').value=c.emoji;

    document.getElementById('modalNotes').value=c.notes;

    document.getElementById('modal').style.display='flex';
}

// Save
function saveCell(){

    cabanas[currentSec][currentIndex]={

        room:
        document.getElementById('modalRoom').value,

        sold:
        document.getElementById('modalSold').value,

        status:
        document.getElementById('modalStatus').value,

        meal:
        document.getElementById('modalMeal').value,

        emoji:
        document.getElementById('modalEmoji').value,

        notes:
        document.getElementById('modalNotes').value
    };

    localStorage.setItem(
        'cabanas',
        JSON.stringify(cabanas)
    );

    renderGrid(currentSec);

    document.getElementById('modal')
    .style.display='none';
}

// Close Modal
document.getElementById('modal')
.onclick=function(e){

    if(e.target==this){

        this.style.display='none';
    }
}

// Clear Section
function clearSection(secName){

    if(confirm(`Очистить ${secName}?`)){

        cabanas[secName]=
        cabanas[secName].map(c=>({

            room:'',
            sold:'',
            status:'free',
            meal:'BB',
            emoji:'',
            notes:''

        }));

        localStorage.setItem(
            'cabanas',
            JSON.stringify(cabanas)
        );

        renderGrid(secName);
    }
}

// SECTION PDF
function saveSectionPDF(secName){

    const section=
    document.getElementById(secName);

    const opt={

        margin:0.5,

        filename:
        secName + '_Cabana.pdf',

        image:{
            type:'jpeg',
            quality:1
        },

        html2canvas:{
            scale:2
        },

        jsPDF:{
            unit:'in',
            format:'a4',
            orientation:'portrait'
        }
    };

    html2pdf()
    .set(opt)
    .from(section)
    .save();
}

</script>

</body>
</html>
