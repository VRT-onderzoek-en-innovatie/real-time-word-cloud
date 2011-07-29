function rect_intersect (ax,ay,aw,ah, bx,by,bw,bh) {
	/* Do the rectangles A and B intersect?
	 * Each are specified by their left-top corner {a,b}{x,y}
	 * and their width and hight {a,b}{w,h} (exclusive)
	 * This function returns either false if the rectangles
	 * do not overlap, or a vector [x,y] to move A away from B
	 */
	
	// Make sure {a,b}{w,h} are positive
	if( aw < 0 ) { ax = ax + aw; aw = -aw; }
	if( ah < 0 ) { ay = ay + ah; ah = -ah; }
	if( bw < 0 ) { bx = bx + bw; bw = -bw; }
	if( bh < 0 ) { by = by + bh; bh = -bh; }

	if( ax+aw <= bx /* A left of B */ ) return false;
	if( bx+bw <= ax /* A right of B */ ) return false;
	if( ay+ah <= by /* A above B */ ) return false;
	if( by+bh <= ay /* A below B */ ) return false;

	// OK, they overlap; Move away in this direction
	var mv = [ (ax+aw/2) - (bx+bw/2) , (ay+ah/2) - (by+bh/2) ];
	{
		var length = Math.sqrt( Math.pow(mv[0],2) + Math.pow(mv[1],2) );
		mv[0] /= length; mv[1] /= length;
	}

	{ // Now find the intersection area to scale that vector
		var ix = Math.max(ax,bx);
		var iy = Math.max(ay,by);
		var ix2 = Math.min(ax+aw, bx+bw);
		var iy2 = Math.min(ay+ah, by+bh);
		var iw = ix2-ix;
		var ih = iy2-iy;
		var area = iw*ih;
		area /= aw*ah;
		mv[0] *= area; mv[1] *= area;
	}

	return mv;
}

Math.round_toward_zero = function (x) { return (x >= 0 ? Math.floor(x) : Math.ceil(x) ); }

TwoDArray = function(width, height) {
	this.width = width;
	this.height = height;
	this.length = width*height;
	this.data = new Array(this.length);
}
TwoDArray.prototype.el = function(x,y) {
	return this.data[ y*this.width + x ];
}
TwoDArray.prototype.setEl = function(x,y,v) {
	this.data[ y*this.width + x ] = v;
}
TwoDArray.prototype.clone = function() {
	var clone = new TwoDArray(this.width, this.height);
	clone.data = this.data.slice();
	return clone;
}

WordCloudAnchor = function(jqelement) {
	this.jqe = jqelement;
	this.cache = {};
};
WordCloudAnchor.prototype.flushCache = function() {
	this.cache = {};
};
WordCloudAnchor.prototype.width = function() {
	if( this.cache.width == undefined ) {
		this.cache.width = this.jqe.width();
	}
	return this.cache.width;
};
WordCloudAnchor.prototype.height = function() {
	if( this.cache.height == undefined ) {
		this.cache.height = this.jqe.height();
	}
	return this.cache.height;
};
WordCloudAnchor.prototype.conePotentialField = function () {
	if( this.cache.pf == undefined ) {
		var cx = this.width()/2;
		var cy = this.height()/2;

		this.cache.pf = new TwoDArray(this.width()+1, this.height()+1);
		for( y=this.height(); y>=0; y-- ) {
		for( x=this.width(); x>=0; x-- ) {
			var dx = x-cx;
			var dy = y-cy;
			this.cache.pf.setEl( x, y, (dx*dx + dy*dy)/(this.width()+this.height()) );
		}}
	}
	return this.cache.pf.clone();
}

WordCloudItem = function(jqelement, anchor) {
	this.jqe = jqelement;
	this.anchor = anchor;
	this.hideThreshold = 0.1;
	this.acc = {x:0, y:0}; // Error accumulator
	this.cache = {};
};
WordCloudItem.prototype.destroy = function () {
	this.jqe.remove();
};
WordCloudItem.prototype.x = function() {
	if( this.cache.x == undefined ) {
		var pos = this.jqe.position();
		this.cache.x = pos.left;
		this.cache.y = pos.top; // If we called position() anyway, update y as well
	}
	return this.cache.x;
};
WordCloudItem.prototype.y = function() {
	if( this.cache.y == undefined ) {
		var pos = this.jqe.position();
		this.cache.y = pos.top;
		this.cache.x = pos.left; // If we called position() anyway, update x as well
	}
	return this.cache.y;
};
WordCloudItem.prototype.width = function() {
	if( this.cache.width == undefined ) {
		this.cache.width = this.jqe.width();
	}
	return this.cache.width;
};
WordCloudItem.prototype.height = function() {
	if( this.cache.height == undefined ) {
		this.cache.height = this.jqe.height();
	}
	return this.cache.height;
};
WordCloudItem.prototype.attached = function() {
	if( this.cache.attached == undefined ) {
		this.cache.attached = ( this.jqe.parent().length != 0 );
	}
	return this.cache.attached;
}
WordCloudItem.prototype.flushCache = function() {
	this.cache = {};
};
WordCloudItem.prototype.move = function (newX, newY) {
	this.jqe.css('left', newX + 'px');
	this.jqe.css('top' , newY + 'px');
	delete this.cache.x; // Flush cache
	delete this.cache.y;
};
WordCloudItem.prototype.moveRel = function (deltaX, deltaY) {
	deltaX += this.acc.x; // Apply accumulated error
	deltaY += this.acc.y;

	var dx = Math.round_toward_zero(deltaX);
	var dy = Math.round_toward_zero(deltaY);

	this.acc.x = deltaX-dx;
	this.acc.y = deltaY-dy;

	this.jqe.css('left', this.x() + dx + 'px')
	        .css('top' , this.y() + dy + 'px');
	delete this.cache.x; // Flush cache
	delete this.cache.y;
};
WordCloudItem.prototype.redraw = function () {
	if( this.size < this.hideThreshold ) { // Remove from DOM
		if( this.attached() ) {
			this.prevpos = { x: this.x(), y: this.y() };
			this.jqe.detach();
			delete this.cache.attached;
		}
	} else { // Make sure it's in the DOM
		if( ! this.attached() ) {
			if(this.prevpos == undefined) {
				this.prevpos = {x: Math.random()*(this.anchor.width()-100), y: Math.random()*(this.anchor.height()-50) };
			}
			this.move( this.prevpos.x, this.prevpos.y );
			this.anchor.jqe.append(this.jqe);
			delete this.cache.attached;
		}
	}
	this.jqe.css('font-size', Math.pow(this.size,.5)*100 + '%');
	delete this.cache.width; // Flush cache
	delete this.cache.height;
};
WordCloudItem.prototype.weight = function () {
	if( this.attached() ) return 50 + this.width()*this.height();
	return 0;
}

FeedBackLoop = function (tooLow, low, high, tooHigh, ewma) {
	if( tooLow == undefined ) tooLow = 0;
	if( low == undefined ) low = 0;
	if( high == undefined ) high = 1E99;
	if( tooHigh == undefined ) tooHigh = 1E99;
	if( ewma == undefined ) ewma = 0;

	// There are 5 zones, devided by 4 threshold:
	//            value < tooLow  : take action to increase value
	//  tooLow <= value < low     : prevent action to decrease value
	//     low <= value < high    : don't interfere
	//    high <= value < tooHigh : prevent action to increase value
	// tooHigh <= value           : take action to decrease value
	this.tooLow = tooLow;
	this.low = low;
	this.high = high;
	this.tooHigh = tooHigh;
	this.register = 0;
	this.ewma = ewma; // = Math.pow( .5, 1/HalfTime )
};
FeedBackLoop.prototype.value = function() {
	return this.register*(1-this.ewma);
};
FeedBackLoop.prototype.newData = function (value) {
	this.register *= this.ewma;
	this.register += value;

	var value = this.value();
	if( value < this.tooLow ) return "inc";
	if( value < this.low ) return "inh dec";
	if( value < this.high ) return "free";
	if( value < this.tooHigh) return "inh inc";
	return "dec";
};

/* static */ FeedBackLoop.prototype.combine = function (/* … */) {
	var result = "free";
	for( var i=0; i < arguments.length; i++ ) {
		var add = arguments[i];
		if( result == "free" ) result = add;
		else if( add == "free" ) result = result;
		else if( add == "inc" || add == "dec" ) result = add;
		else if( result == "inc" && add == "inh inc" ) result = "free";
		else if( result == "inc" && add == "inh dec" ) result = result;
		else if( result == "dec" && add == "inh dec" ) result = "free";
		else if( result == "dec" && add == "inh inc" ) result = result;
		else console.log("FeedBackLoop.combine("+result+","+add+") undefined\n");

		if( result == "inh inc" || result == "inh dec" ) result = "free";
	}
	return result;
}

WordCloud = function(wordfreq, anchor, template) {
	this.wordfreq = wordfreq;
	this.anchor = new WordCloudAnchor(anchor);
	this.template = template;

	this.hideThreshold = 0.1;

	// Keep fill-grade between 20% and 50%
	this.fill_feedback = new FeedBackLoop(.2, .2, .4, .4, 0);

	// Prevent increase if CPU is >50%; decrease if >80%
	this.cpu_feedback = new FeedBackLoop(0, 0, 50, 80, .95);

	var that = this;
	this.wordfreq.cb.newWord.push( function(newWord) { that.newWord(newWord); } );
	this.wordfreq.cb.updatedWord.push( function(word, count) { that.updateWord(word,count); } );
	this.wordfreq.cb.removedWord.push( function(word) { that.removeWord(word); } );
	this.wordfreq.cb.tick.push( function(reduce) {
			that.hideThreshold = Math.max(0.1,reduce(that.hideThreshold));
		} );
	this.words = {};
};

WordCloud.prototype.newWord = function (newWord) {
	var jqitem = this.template.clone().text(newWord);
	this.words[newWord] = new WordCloudItem(jqitem, this.anchor);
};
WordCloud.prototype.updateWord = function (word, count) {
	var wordObj = this.words[ word ];
	this.fill_feedback.weight -= wordObj.weight();
	wordObj.size = count;
	wordObj.redraw();
	this.fill_feedback.weight += wordObj.weight();
};
WordCloud.prototype.removedWord = function (word) {
	if( this.words[ word ] != undefined ) {
		this.fill_feedback.weight -= wordObj.weight();;
		this.words[ word ].destroy(); // manually call destructor FIXME (if possible in JS)
		delete this.words[ word ];
	}
}

WordCloud.prototype.redraw = function() {
	var startTime = +new Date();

	// Create potentialField
	pf = this.anchor.conePotentialField();
	//var pf = this.anchor.conePotentialField();
	for( var word in this.words) {
		var wordObj = this.words[ word ];
		if( ! wordObj.attached() ) continue;

		var factor = 2;
		var border = 5;
		var l=-border, t=-border, r=wordObj.width()+border, b=wordObj.height()+border;
		var d = 1;
		while(t<=b && l<=r) {
			// Increment the border at distance d
			for(var x=l; x<=r; x++) {
				pf.setEl( wordObj.x()+x, wordObj.y()+t,
					pf.el( wordObj.x()+x, wordObj.y()+t ) + factor*d ); // top row
				if( t != b ) // check that we don't run over the same row twice
				pf.setEl( wordObj.x()+x, wordObj.y()+b,
					pf.el( wordObj.x()+x, wordObj.y()+b ) + factor*d ); // bottom row
			}
			for(var y=t+1; y<b; y++) { // Exclude first & last row (already done above)
				pf.setEl( wordObj.x()+l, wordObj.y()+y,
					pf.el( wordObj.x()+l, wordObj.y()+y ) + factor*d ); // left column
				if( l != r )
				pf.setEl( wordObj.x()+r, wordObj.y()+y,
					pf.el( wordObj.x()+r, wordObj.y()+y ) + factor*d ); // right column
			}
			l++; r--; t++; b--; // Shrink box by 1 pixel
			d++; // increment distance
		}
	}

	for( var word in this.words ) {
		var wordObj = this.words[ word ];
		if( ! wordObj.attached() ) continue;

		// Sense potential {top,bottom,left,right}
		var pt=0,pb=0,pl=0,pr=0;
		for( x=wordObj.width()+1; x>=0; x-- ) {
			pt += pf.el( wordObj.x() + x, wordObj.y() );
			pb += pf.el( wordObj.x() + x, wordObj.y() + wordObj.height()+1 );
		}
		for( y=wordObj.height()+1; y>=0; y-- ) {
			pl += pf.el( wordObj.x(), wordObj.y() + y );
			pr += pf.el( wordObj.x() + wordObj.width()+1, wordObj.y() + y );
		}

		var mvx = (pl - pr) / wordObj.height() * .1;
		var mvy = (pt - pb) / wordObj.width() * .1;

		wordObj.moveRel( mvx, mvy );
	}

	{ // Feedback loops
		// Fill
		var filled = 0;
		for( var word in this.words ) {
			var wordObj = this.words[ word ];
			filled += wordObj.weight();
		}
		filled /= this.anchor.width() * this.anchor.height();

		// CPU
		var dt = ((+new Date())-startTime);


		var action =
			this.cpu_feedback.combine( this.fill_feedback.newData(filled),
			                           this.cpu_feedback.newData(dt) );

		if( action != "free" ) {
			var changed = false;
			if( action == "inc" && this.hideThreshold > 0.1 ) {
				this.hideThreshold /= 1.05;
				changed = true;
			} else if( action == "dec" ) {
				this.hideThreshold *= 1.05;
				changed = true;
			}
			if( changed ) {
				console.log("Feedback loop: Fill("+this.fill_feedback.value()+") "+
				            "CPU("+this.cpu_feedback.value()+") "+
							"=> "+action+" to "+this.hideThreshold+"\n");
				for( var word in this.words ) {
					var wordObj = this.words[ word ];
					wordObj.hideThreshold = this.hideThreshold;
					wordObj.redraw();
				}
			}
		}
	}
};

function DEBUG_display_pf(pf) {
	var debug_ctx = $("#debug")[0].getContext("2d");
	var image = debug_ctx.createImageData( pf.width, pf.height );

	var min=pf.data[0], max=pf.data[0];
	for( var i=0; i < pf.length; i++ ) {
		if( pf.data[i] < min ) min = pf.data[i];
		if( pf.data[i] > max ) max = pf.data[i];
	}
	for( var i=0; i < pf.length; i++ ) {
		image.data[ i*4 + 0 ] = (pf.data[i] - min)*255/(max-min); // R
		image.data[ i*4 + 1 ] = (pf.data[i] - min)*255/(max-min); // G
		image.data[ i*4 + 2 ] = (pf.data[i] - min)*255/(max-min); // B
		image.data[ i*4 + 3 ] = 255; // A
	}

	debug_ctx.putImageData(image, 0, 0);
}
function DEBUG_clear_pf() {
	var debug_ctx = $("#debug")[0].getContext("2d");
	var image = debug_ctx.createImageData( pf.width, pf.height );
	debug_ctx.putImageData(image, 0, 0);
}
