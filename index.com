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

/* BUTTONS */
button{
    background:#677D73;
    color:white;
    border:none;
    padding:10px 15px;
    border-radius:20px;
    margin:5px;
    cursor:pointer;
}

/* INFO */
.info{
    display:none;
    background:white;
    padding:10px;
    border-radius:15px;
    margin-bottom:10px;
}

/* SECTIONS */
.section{
    background:white;
    padding:15px;
    border-radius:20px;
    margin-bottom:15px;
}

/* GRID */
.grid{
    display:grid;
    grid-template-columns:repeat(auto-fill,minmax(120px,1fr));
    gap:10px;
    margin-top:10px;
}

/* CELLS */
.cell{
    padding:10px;
    border-radius:15px;
    text-align:center;
    font-size:13px;
}

/* COLORS */
.free{background:#A7CFA5;}
.booked{background:#E26D6D;}
.complimentary{background:#E8D27C;}
.event{background:#7DAAE3;}
.villa{background:#FFA500;}

</style>
</head>

<body>

<h1>Cabana Booking</h1>

<button onclick="toggleInfo()">ℹ️ Information</button>

<button onclick="savePDF('Escape')">🏝️ Escape (21)</button>
<button onclick="savePDF('Lotus')">🪷 Lotus (8)</button>
<button onclick="savePDF('Joystone')">🏖️ Joy Stone (18)</button>

<div id="info" class="info">
🟩 Free<br>
🟥 Booked<br>
🟨 Complimentary<br>
🟦 Event<br>
🟧 Villa
</div>

<div id="app"></div>

<script>

/* DATA */
const types=[
    {name:"Escape",icon:"🏝️",count:21},
    {name:"Lotus",icon:"🪷",count:8},
    {name:"Joystone",icon:"🏖️",count:18}
];

let data = JSON.parse(localStorage.getItem("data")) || {};

/* INIT */
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
const app=document.getElementById("app");

function render(){

    app.innerHTML="";

    types.forEach(t=>{

        const section=document.createElement("div");
        section.className="section";

        section.innerHTML=`
            <h2 onclick="toggle('${t.name}')">
                ${t.icon} ${t.name}
            </h2>

            <div id="${t.name}" class="info" style="display:none;">
                <div class="grid">

                    ${data[t.name].map((c,i)=>`

                        <div class="cell ${c.status}">
                            <b>${t.name} ${i+1}</b><br>
                            Room: ${c.room || "-"}<br>
                            ${c.emoji || ""}
                        </div>

                    `).join("")}

                </div>
            </div>
        `;

        app.appendChild(section);
    });
}

/* TOGGLE FIX */
function toggle(id){
    const el=document.getElementById(id);
    el.style.display = el.style.display==="block" ? "none" : "block";
}

/* INFO */
function toggleInfo(){
    const el=document.getElementById("info");
    el.style.display = el.style.display==="block" ? "none" : "block";
}

/* PDF (SAFE VERSION) */
function savePDF(name){

    let html="";

    data[name].forEach((c,i)=>{

        let bg="#A7CFA5";

        if(c.status==="booked") bg="#E26D6D";
        if(c.status==="complimentary") bg="#E8D27C";
        if(c.status==="event") bg="#7DAAE3";
        if(c.status==="villa") bg="#FFA500";

        html+=`
        <div style="
            padding:20px;
            margin:10px;
            border-radius:15px;
            background:${bg};
            font-family:Arial;
        ">
            <h2>${name} ${i+1}</h2>
            Room: ${c.room || "-"}<br>
            ${c.emoji || ""}
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
        jsPDF:{format:"a4"}
    })
    .from(el)
    .save();
}

/* START */
render();

</script>

</body>
</html>
