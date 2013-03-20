App = @App || {}


App.config = 
	data_path: "gov_codes_by_purpose.csv"
	codes_path: "codes.json"

	vis:
		h: 900
		w: 900



App.initialize = (csv_url) ->
	d3.json(App.config.codes_path, (json) ->
		App.codes = json
	)
	d3.csv(csv_url, (data) ->
		console.log data



		crs_codes = _.uniq(d.crs for d in data)
		adt_codes = _.uniq(d.adt for d in data)
		codes = _.sortBy(_.union(crs_codes, adt_codes), (d) -> d)
		sectors = _.uniq( d[0..2]for d in codes)
		supersectors = _.uniq(d[0] for d in sectors)

		console.log "supersectors:", supersectors, "sectors:", sectors, "codes: ", codes #, "crs:", crs_codes, "adt:", adt_codes

		amounts = (d.sum for d in data)
		max_amount = d3.max amounts
		total_amount = d3.sum amounts

		console.log "amounts", amounts, "max_amount", max_amount, "total_amount", total_amount

		box_width = Math.round( (App.config.vis.h-20) / codes.length)

		purpose_scale = d3.scale.ordinal()
			.domain(codes)
			.rangeBands([0, App.config.vis.h], .1)

		supersector_scale_numeric = d3.scale.ordinal()
			.domain(supersectors)
			.rangeBands([1,0],.2)

		supersector_scale_color = (ss) ->
			num = supersector_scale_numeric(ss)
			d3.scale.linear()
				.domain([1,0])
				.range(["red", "blue"])
				(num)
		
		supersector_scale = d3.scale.ordinal()
			.domain(supersectors)
			.range(["crimson", "darkorange", "yellow", "green", "lightblue", "indigo", "violet", "darkgray"])

		console.log supersector_scale_numeric("3"), supersector_scale("3")
		console.log supersector_scale_numeric("9"), supersector_scale("9")

		amount_scale = d3.scale.linear()
			.domain([0,.0001, max_amount])
			.range([0,.1,1])

		App.svg = d3.select('#heatmap')
			.append("svg")
			.attr("height", App.config.vis.h)
			.attr("width", App.config.vis.w)


		boxes = App.svg.selectAll("box")
				.data(data)
		boxes
			.enter().append("svg:rect")
				.attr("class", (d) -> "crs_#{d.crs} adt_#{d.adt} box")
				.attr("id", (d) -> "crs_#{d.crs}_to_adt_#{d.adt}")
				.attr("height", box_width)
				.attr("width", box_width)
				.attr("y", (d) -> App.config.vis.h - purpose_scale(d.crs))
				.attr("x", (d) -> purpose_scale(d.adt))
				.style("opacity", 0)
				.style("fill", "white")
				.on("mouseover", display_tootip)
				.on("mouseout", hide_tooltip)
		boxes
			.transition()
				.delay((d,i) -> (max_amount/d.sum) *10 )
				.duration(500)
				.style("fill", (d) -> supersector_scale(d.adt[0]))
				.style("opacity", (d) -> amount_scale(d.sum))
				##.style("stroke", (d) -> supersector_scale(d.crs[0]))




	)


display_tootip = (d,i) ->
	vert_margin = $(".page-header").height() + 40
	horiz_margin = 40
	m = d3.mouse(this)

	if crs_code = _.findWhere(App.codes, {code: d.crs })
		crs_text = "<b>#{crs_code.name}</b> (#{crs_code.code})"
	else
		crs_text = d.crs

	if adt_code = _.findWhere(App.codes, {code: d.adt})
		adt_text = "<b>#{adt_code.name}</b> (#{adt_code.code})"
	else
		adt_text = d.adt

	$('#tooltip')
		.html("$#{d3.format(',.1s')(d.sum)} from CRS #{crs_text} to ADT #{adt_text} in #{d.count} records.")
		.show()
		.css("left", m[0])
		.css("top", m[1] + vert_margin)

	#$(this).addClass("active-box").css("stroke", "black")
	
hide_tooltip = (d,i) ->
	$('#tooltip')
		.text("")
		.hide()

	#$(".active-box").css("stroke", "transparent" )


App.initialize(App.config.data_path)