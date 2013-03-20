@App = @App || {}


App.config = 
	data_path: "gov_codes_by_purpose.csv"
	codes_path: "codes.json"

	vis:
		h: 900
		w: 900
		r: 300



App.initialize = (csv_url) ->
	d3.json(App.config.codes_path, (json) ->
		App.codes = json
	)
	d3.csv(csv_url, (data) ->
		console.log data


		crs_codes = _.uniq(d.crs for d in data)
		adt_codes = _.uniq(d.adt for d in data)
		codes = _.sortBy(_.union(crs_codes, adt_codes), (d) -> d)
		sectors =  App.sectors = _.uniq( d[0..2]for d in codes)
		supersectors = _.uniq(d[0] for d in sectors)

		amounts = (d.sum for d in data)
		max_amount = d3.max amounts
		total_amount = d3.sum amounts

		counts = (d.count for d in data)
		max_count = d3.max counts

		# console.log "amounts", amounts, "max_amount", max_amount, "total_amount", total_amount
		console.log max_count

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
		
		App.supersector_scale = d3.scale.ordinal()
			.domain(supersectors)
			.range(["crimson", "darkorange", "yellow", "green", "lightblue", "indigo", "violet", "darkgray"])

		App.sector_scale = d3.scale.ordinal()
			.domain(sectors)
			.range(['#e61c37', '#e61c53', '#e61c6e', '#e61c8a', '#e61ca5', '#e61cc1', 
				'#e61cdc', '#d31ce6', '#b81ce6', '#9c1ce6', '#811ce6', '#651ce6', '#4a1ce6', 
				'#2f1ce6', '#1c25e6', '#1c41e6', '#1c5ce6', '#1c78e6', '#1d93e6', '#1dafe6', 
				'#1dcae6', '#1de6e6', '#1de6ca', '#1de6af', '#1de693', '#1de678', '#1de65d', 
				'#1de641', '#1de626', '#2fe61d', '#4be61d', '#66e61d', '#81e61d', '#9de61d', 
				'#b8e61d', '#d3e61d', '#e6dc1d', '#e6c11e', '#e6a61e', '#e68b1e', '#e66f1e', 
				'#e6541e', '#e6391e', '#e61e1e'])


		amount_scale = d3.scale.linear()
			.domain([0,.0001, max_amount])
			.range([0,.1,1])

		App.count_scale = d3.scale.linear()
			.domain([1, max_count])
			.range([.1,1])

		App.svg = d3.select('#pies')
			.append("svg")
			.attr("height", App.config.vis.h)
			.attr("width", App.config.vis.w)


		App.aid_by_crs = d3.nest()
			.key((d) -> d.crs[0..2])
			.rollup((data) -> 
				{
					sum: d3.sum(d.sum for d in data) 
					count: d3.sum(d.sum for d in data) 
				})
			.entries(data)

		App.aid_by_adt = d3.nest()
			.key((d) -> d.adt[0..2])
			.rollup((data) -> 
				{
					sum: d3.sum(d.sum for d in data) 
					count: d3.sum(d.sum for d in data) 
				})
			.entries(data)

		App.code_chart_this_data App.aid_by_crs
	)

App.code_chart_this_data = (nested_data) ->

	pie_layout = d3.layout.pie()
		.value((d) -> d.values.sum)
		.sort(null)

	arc = d3.svg.arc()
		.innerRadius(0)
		.outerRadius(App.config.vis.r)

	arcTween = (b) ->
	  i = d3.interpolate({value: b.previous}, b)
	  (t) -> arc(i(t))

	pie = App.svg.selectAll('.slice')
		.data(pie_layout(nested_data), (d) -> d.data.key)
	
	pie.enter().append('svg:path')
		.attr('transform', "translate(#{App.config.vis.r}, #{App.config.vis.r})")
		.attr("class", (d) -> "slice #{d.data.key}")
		.attr("id", (d) -> "slice_#{d.data.key}")
		.attr("fill", (d) -> App.sector_scale(d.data.key))
		.style("stroke", "white")
		.on("mouseover", display_tootip)
		.append('title')
			.text((d) -> "$#{d3.format(',.2s') d.data.values.sum} 
				in #{d.data.key} 
				(#{ d3.format(',.2s') d.data.values.count} records)")

	pie.exit().remove()

	pie.transition()
		.ease('elastic')
		.duration(750)	
		.style("opacity", (d) -> App.count_scale(d.data.values.count) )
		.attrTween("d", arcTween )
	
	groups_text = App.svg.selectAll(".label")
	      .data(d.key for d in nested_data)
	  .enter().append("text")
	  	.attr("class", "label")
	    .attr("x", 5)
	    .attr("dy", 15)

	groups_text.append("textPath")
	    .attr("xlink:href", (d, i) -> "#slice_" + d)
	    .text(String);


			
			
			



display_tootip = (d,i) ->
	vert_margin = $(".page-header").height() + 40 + (App.config.vis.r * 1.5)
	horiz_margin = 40 + (App.config.vis.r * 1.5)
	m = d3.mouse(this)

	$('#tooltip')
		.html("$#{d3.format(',.1s')(d.data.values)} in #{d.data.key} ")
		.show()
		.css("left", m[0] + horiz_margin )
		.css("top", m[1] + vert_margin)


	
hide_tooltip = (d,i) ->
	$('#tooltip')
		.text("")
		.hide()



App.initialize(App.config.data_path)