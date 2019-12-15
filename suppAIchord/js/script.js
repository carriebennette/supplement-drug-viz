
////////////////////////////////////////////////////////////
//////////////////////// Set-Up ////////////////////////////
////////////////////////////////////////////////////////////
var margin = {left:50, top:0, right:0, bottom:0},
	width = Math.min(window.innerWidth, 1100) - margin.left - margin.right,
    height = Math.min(window.innerWidth, 900) - margin.top - margin.bottom,
    innerRadius = Math.min(width, height) * .30,
    outerRadius = innerRadius * 1.05;

////////////////////////////////////////////////////////////
/////////// Create scale and layout functions //////////////
////////////////////////////////////////////////////////////
var colors = d3.scale.ordinal()
    .domain(d3.range(Names.length))
	.range(colors);

var chord = d3.layout.chord()
    .padding(.003)
    .sortChords(d3.descending) 
	.matrix(matrix);

var arc = d3.svg.arc()
    .innerRadius(innerRadius*1.01)
    .outerRadius(outerRadius);

var path = d3.svg.chord()
	.radius(innerRadius);

////////////////////////////////////////////////////////////
////////////////////// Create SVG //////////////////////////
////////////////////////////////////////////////////////////

var svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
	.append("g")
    .attr("transform", "translate(" + (width/2 + margin.left) + "," + (height/2 + margin.top) + ")");

////////////////////////////////////////////////////////////
/////////////// Create the gradient fills //////////////////
////////////////////////////////////////////////////////////

//Create the gradients definitions for each chord
var grads = svg.append("defs").selectAll("linearGradient")
	.data(chord.chords())
   .enter().append("linearGradient")
    //Create the unique ID for this specific source-target pairing
	.attr("id", function(d) { return "gradientChord-" + d.source.index + "-" + d.target.index; })
	.attr("gradientUnits", "userSpaceOnUse")
	//Find the location where the source chord starts
	.attr("x1", function(d,i) { return innerRadius * Math.cos((d.source.endAngle-d.source.startAngle)/2 + d.source.startAngle - Math.PI/2); })
	.attr("y1", function(d,i) { return innerRadius * Math.sin((d.source.endAngle-d.source.startAngle)/2 + d.source.startAngle - Math.PI/2); })
	//Find the location where the target chord starts 
	.attr("x2", function(d,i) { return innerRadius * Math.cos((d.target.endAngle-d.target.startAngle)/2 + d.target.startAngle - Math.PI/2); })
	.attr("y2", function(d,i) { return innerRadius * Math.sin((d.target.endAngle-d.target.startAngle)/2 + d.target.startAngle - Math.PI/2); })
//Set the starting color (at 0%)
grads.append("stop")
	.attr("offset", "0%")
	.attr("stop-color", function(d){ return colors(d.source.index); });
//Set the ending color (at 100%)
grads.append("stop")
	.attr("offset", "100%")
	.attr("stop-color", function(d){ return colors(d.target.index); });

////////////////////////////////////////////////////////////
////////////////// Draw outer Arcs /////////////////////////
////////////////////////////////////////////////////////////

var outerArcs = svg.selectAll("g.group")
	.data(chord.groups)
	.enter().append("g")
	.attr("class", "group")
	.on("mouseover", fade(.1))
	.on("mouseout", fade(opacityDefault))
	.append("a")
	.attr("href", function(d, i) { return "http://supp.ai/a/" + Names[i] + "/" + CUIs[i]; }); //link to SuppAI for each arc/name

outerArcs.append("path")
	.style("fill", function(d) { return colors(d.index); })
	.attr("d", arc)
	.append("title");

////////////////////////////////////////////////////////////
////////////////// Append Names ////////////////////////////
////////////////////////////////////////////////////////////

	//Append the label names on the outside
	outerArcs.append("text")
	.each(function(d) { d.angle = (d.startAngle + d.endAngle) / 2; })
	.attr("dy", ".35em")
	.attr("class", "titles")
	.attr("text-anchor", function(d) { return d.angle > Math.PI ? "end" : null; })
	.attr("transform", function(d) {
			return "rotate(" + (d.angle * 180 / Math.PI - 90) + ")"
			+ "translate(" + (outerRadius + 10) + ")"
			+ (d.angle > Math.PI ? "rotate(180)" : "");
	})
	.text(function(d,i) { 
		if(d.value > 300) {return Names[i]}
		else {return ""} ;})

////////////////////////////////////////////////////////////
////////////////// Draw inner chords ///////////////////////
////////////////////////////////////////////////////////////

svg.selectAll("path.chord")
	.data(chord.chords)
	.enter().append("path")
	.attr("class", "chord")
	.style("fill", function(d){ return "url(#gradientChord-" + d.source.index + "-" + d.target.index + ")"; })
	.style("opacity", opacityDefault)
	.attr("d", path)
	.on("mouseover", mouseoverChord)
	.on("mouseout", mouseoutChord);

////////////////////////////////////////////////////////////
////////////////// Extra Functions /////////////////////////
////////////////////////////////////////////////////////////

//Returns an event handler for fading a given chord group.
function fade(opacity) {
  return function(d,i) {
    svg.selectAll("path.chord")
        .filter(function(d) { return d.source.index != i && d.target.index != i; })
		.transition()
        .style("opacity", opacity);
  };
}//fade

//Highlight hovered over chord
function mouseoverChord(d,i) {
	
	svg.selectAll("path.chord")
		.transition()
		.style("opacity", 0.1);
	
	d3.select(this)
		.transition()
        .style("opacity", 1);

    d3.select("#tooltip")
    	.style("left", (d3.event.pageX - 20) + "px")   
    	.style("top", (d3.event.pageY + 20) + "px")
    	.text(Names[d.source.index] + " + " + Names[d.target.index] + ": " + d.source.value + " papers") 

    d3.select("#tooltip").classed("hidden", false);

}

function mouseoutChord(d) {
	
	svg.selectAll("path.chord")
		.transition()
		.style("opacity", opacityDefault);

	d3.select("#tooltip").classed("hidden", true);
}

