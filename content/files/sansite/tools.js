var aboutoffb = new Image();
aboutoffb.src="images/aboutoff.gif";
var aboutonb = new Image();
aboutonb.src = "images/abouton.gif";
var aboutglowb = new Image();
aboutglowb.src = "images/aboutglow.gif";

var emailoffb = new Image();
emailoffb.src="images/emailoff.gif";
var emailonb = new Image();
emailonb.src = "images/emailon.gif";
var emailglowb = new Image();
emailglowb.src = "images/emailglow.gif";

var galleryoffb = new Image();
galleryoffb.src="images/galleryoff.gif";
var galleryonb = new Image();
galleryonb.src = "images/galleryon.gif";
var galleryglowb = new Image();
galleryglowb.src = "images/galleryglow.gif";

var homeoffb = new Image();
homeoffb.src="images/homeoff.gif";
var homeonb = new Image();
homeonb.src = "images/homeon.gif";
var homeglowb = new Image();
homeglowb.src = "images/homeglow.gif";

var randomoffb = new Image();
randomoffb.src="images/randomoff.gif";
var randomonb = new Image();
randomonb.src = "images/randomon.gif";
var randomglowb = new Image();
randomglowb.src = "images/randomglow.gif";

var resumeoffb = new Image();
resumeoffb.src="images/resumeoff.gif";
var resumeonb = new Image();
resumeonb.src = "images/resumeon.gif";
var resumeglowb = new Image();
resumeglowb.src = "images/resumeglow.gif";



function revertAll() {
	document.getElementById('homebutton').src = homeoffb.src;
	document.getElementById('gallerybutton').src = galleryoffb.src;
	document.getElementById('resumebutton').src = resumeoffb.src;
	document.getElementById('aboutbutton').src = aboutoffb.src;
	document.getElementById('randombutton').src = randomoffb.src;
	document.getElementById('emailbutton').src = emailoffb.src;
}

function thisPage(name) {
	switch(name) {
		case "home":
			document.getElementById('homebutton').src = homeonb.src;
			homeoffb.src = homeonb.src;
			break;
		case "gallery":
			document.getElementById('gallerybutton').src = galleryonb.src;
			galleryoffb.src = galleryonb.src;
			break;
                case "resume":
                        document.getElementById('resumebutton').src = resumeonb.src;
			resumeoffb.src = resumeonb.src;
                        break;
                case "about":
                        document.getElementById('aboutbutton').src = aboutonb.src;
			aboutoffb.src = aboutonb.src;
                        break;
                case "random":
                        document.getElementById('randombutton').src = randomonb.src;
			randomoffb.src = randomonb.src;
                        break;
                case "email":
                        document.getElementById('emailbutton').src = emailonb.src;
			emailoffb.src = emailonb.src;
                        break;
	}
}

function switchImages(image) {
	revertAll();
	switch(image) {
                case "home":
                        document.getElementById('homebutton').src = homeglowb.src;
                        break;
                case "gallery":
                        document.getElementById('gallerybutton').src = galleryglowb.src
                        break;
                case "resume":
                        document.getElementById('resumebutton').src = resumeglowb.src
                        break;
                case "about":
                        document.getElementById('aboutbutton').src = aboutglowb.src
                        break;
                case "random":
                        document.getElementById('randombutton').src = randomglowb.src
                        break;
                case "email":
                        document.getElementById('emailbutton').src = emailglowb.src
                        break;

	}
}
