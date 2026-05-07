<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cabana Booking</title>

<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>

<style>

body{
    font-family: Arial;
    margin:0;
    padding:20px;
    background:#F4F3EF;
}

h1{
    text-align:center;
    color:#677D73;
}

button{
    background:#677D73;
    color:white;
    border:none;
    padding:10px 15px;
    border-radius:20px;
    margin:5px;
}

/* INFO */
.content{
    display:none;
    padding:10px;
    background:white;
    border-radius:15px;
}

/* GRID */
.grid{
    display:grid;
    grid-template-columns:repeat(auto-fill,minmax(110px,1fr));
    gap:10px;
}

.cell{
    padding:10px;
    border-radius:15px;
    text-align:center;
    font-size:13px;
    cursor:pointer;
}

/* MODAL */
.modal{
    display:none;
    position:fixed;
    top:0;left:0;
    width:100%;height:100%;
    background:rgba(0,0,0,0.4);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:white;
    padding:20px;
    width:300px;
    border-radius:15px;
}

input,select,textarea{
    width:100%;
    margin:5px 0;
    padding:8px;
}

/* optional info style */
.info-box{
    background:white;
    padding:10px;
    border-radius:15px;
    margin-bottom:10px;
}

</style>
</head>

<body>

<h1>Cabana Booking</h1>

<button onclick="toggle('info')">ℹ️ Information</button>

<button onclick="savePDF('Escape')">🏝️ Escape PDF</button>
<button onclick="savePDF('Lotus')">🪷 Lotus PDF</button>
<button onclick="savePDF('Joystone')">🏖️ Joy Stone PDF</button>

<div id="info" class="content">

<div class="info-box">
🟩 Free<br>
🟥 Booked<br>
🟨 Complimentary<br>
🟦 Event<br>
🟧 Villa
</div>

</div>

<div id="sections"></div>

<!-- MODAL -->
<div class="modal" id="modal">
<div class="modal-content">

<input id="room" placeholder="Room">
<input id="sold" placeholder="Sold">

<select id="status">
<option value="free">Free</option>
<option value="booked">Booked</option>
<option value="complimentary">Complimentary</option>
<option value="event">Event</option>
<option value="villa">Villa 🟧</option>
</select>

<select id="meal">
<option>BB</option>
<option>All Inclusive</option>
</select>

<input id="emoji" placeholder="Emoji">
<textarea id="notes" placeholder="Notes"></textarea>

<button onclick="save()">Save</button>

</div>
</div>

<script>

/* DATA */
const types = [
    {name:"Escape",icon:"🏝️",count:21},
    {name:"Lotus",icon:"🪷",count:8},
    {name:"Joystone",icon:"🏖️",count:18}
];

let data = JSON.parse(localStorage.getItem("data")) || {};

types.forEach(t=>{
    if(!data[t.name]){
        data[t.name]=Array.from({length:t.count},()=>({
            room:"",
            sold:"",
            status:"free",
            meal:"BB",
            emoji:"",
            notes:""
        }));
    }
});

/* RENDER */
const wrap=document.getElementById("sections");

types.forEach(t=>{

    const div=document.createElement("div");

    div.innerHTML=`
        <h2 onclick="toggle('${t.name}')">${t.icon} ${t.name}</h2>
        <div id="${t.name}" class="content">
            <div class="grid"></div>
        </div>
    `;

    wrap.appendChild(div);

    draw(t.name);
});

function draw(name){

    const grid=document.querySelector(`#${name} .grid`);
    grid.innerHTML="";

    data[name].forEach((c,i)=>{

        const div=document.createElement("div");

        /* 🔥 FIXED COLOR SYSTEM (NO CSS BUGS) */
        let bg="#A7CFA5";

        if(c.status==="booked") bg="#E26D6D";
        if(c.status==="complimentary") bg="#E8D27C";
        if(c.status==="event") bg="#7DAAE3";
        if(c.status==="villa") bg="#FFA500";

        div.style.background=bg;

        div.className="cell";

        div.innerHTML=`
            <b>${name} ${i+1}</b><br>
            Room: ${c.room||"-"}<br>
            ${c.emoji||""}
        `;

        div.onclick=()=>open(name,i);

        grid.appendChild(div);
    });
}

/* TOGGLE FIX */
function toggle(id){
    const el=document.getElementById(id);
    el.style.display = el.style.display==="block" ? "none" : "block";
}

/* MODAL */
let cur,idx;

function open(n,i){

    cur=n;
    idx=i;

    const c=data[n][i];

    room.value=c.room;
    sold.value=c.sold;
    status.value=c.status;
    meal.value=c.meal;
    emoji.value=c.emoji;
    notes.value=c.notes;

    modal.style.display="flex";
}

function save(){

    data[cur][idx]={
        room:room.value,
        sold:sold.value,
        status:status.value,
        meal:meal.value,
        emoji:emoji.value,
        notes:notes.value
    };

    localStorage.setItem("data",JSON.stringify(data));

    modal.style.display="none";

    draw(cur);
}

/* CLOSE */
modal.onclick=e=>{
    if(e.target===modal) modal.style.display="none";
}

/* PDF */
function savePDF(name){

    const icon={
        Escape:"🏝️",
        Lotus:"🪷",
        Joystone:"🏖️"
    }[name];

    let html="";

    data[name].forEach((c,i)=>{

        let bg="#A7CFA5";

        if(c.status==="booked") bg="#E26D6D";
        if(c.status==="complimentary") bg="#E8D27C";
        if(c.status==="event") bg="#7DAAE3";
        if(c.status==="villa") bg="#FFA500";

        html+=`
        <div style="
            height:100vh;
            padding:40px;
            box-sizing:border-box;
            page-break-after:always;
            display:flex;
            flex-direction:column;
            justify-content:center;
            align-items:center;
            background:${bg};
            font-family:Arial;
        ">

            <h1>${icon} ${name}</h1>
            <h2>Cabana ${i+1}</h2>

            <p>Room: ${c.room||"-"}</p>
            <p>Sold: ${c.sold||"-"}</p>
            <p>Meal: ${c.meal}</p>
            <p>${c.emoji||""}</p>
            <p>${c.notes||""}</p>

        </div>
        `;
    });

    const el=document.createElement("div");
    el.innerHTML=html;

    html2pdf()
    .set({
        margin:0,
        filename:name+".pdf",
        html2canvas:{scale:2},
        jsPDF:{format:"a4",orientation:"portrait"}
    })
    .from(el)
    .save();
}

</script>

</body>
</html>
