require 'cairo'

function iarray(iter)
	local o = {}
	local c = 1
	for f in iter do
		o[c] = f
		c = c + 1
	end
	return o
end

function xprint(cr,text,xpos,ypos)
	font = "Mono"
	font_size = 12
	red,green,blue,alpha = 1,1,1,1
	font_slant = CAIRO_FONT_SLANT_NORMAL
	font_face = CAIRO_FONT_WEIGHT_NORMAL

	cairo_select_font_face (cr, font, font_slant, font_face);
	cairo_set_font_size (cr, font_size)
	cairo_set_source_rgba (cr,red,green,blue,alpha)
	
	local offset = 0
	for line in string.gmatch(text, "[^\n]+") do
		cairo_move_to (cr,xpos,ypos+offset)
		cairo_show_text (cr,line)
		offset = offset + font_size
	end

	cairo_stroke (cr)
end

function xdivider(cr,startx,starty,endx,endy)
	line_width=1
	line_cap=CAIRO_LINE_CAP_SQUARE
	red,green,blue,alpha=1,1,1,1

	cairo_set_line_width (cr,line_width)
	cairo_set_line_cap  (cr, line_cap)
	cairo_set_source_rgba (cr,red,green,blue,alpha)
	cairo_move_to (cr,startx,starty)
	cairo_line_to (cr,endx,endy)
	cairo_stroke (cr)
end

function xtable(cr,t,xpos,ypos)
	--otable(t)
	
	local extent = {}
	extent.x = xpos
	extent.y = ypos
	extent.width = 0
	extent.height = 0
	
	font = "Mono"
	font_size = 12
	red,green,blue,alpha = 1,1,1,1
	font_slant = CAIRO_FONT_SLANT_NORMAL
	font_face = CAIRO_FONT_WEIGHT_NORMAL

	cairo_select_font_face (cr, font, font_slant, font_face);
	cairo_set_font_size (cr, font_size)
	cairo_set_source_rgba (cr,red,green,blue,alpha)
	
	local offset = font_size
	

	cairo_move_to (cr,xpos,ypos+offset)
	for k,v in pairs(t.columns) do
		if t.format[v].show == true then
			local z = v..string.rep(" ", (t.format[v].width - #v)).."  "
			cairo_show_text (cr,z)
		end
	end
	offset = offset + font_size

	for i,row in pairs(t.rows) do
		mwidth = 0
		cairo_move_to (cr,xpos,ypos+offset)
		for k,v in pairs(t.columns) do
			if t.format[v].show == true then
				local z = t.rows[i][v]..string.rep(" ", (t.format[v].width - #t.rows[i][v])).."  "
				cairo_show_text (cr,z)
				local ex = cairo_text_extents_t:create()
				cairo_text_extents(cr,z,ex)
				--if ex.width > extent.width then extent.width = ex.width end
				--if ex.height > extent.height then extent.height = ex.height end
				mwidth = mwidth + ex.x_advance
				--print(ex.x_advance,ex.y_advance)
			end
		end
		if mwidth > extent.width then extent.width = mwidth end
		offset = offset + font_size
	end
	
	extent.height = offset - font_size

	cairo_stroke (cr)
	return extent
end

function cmdo(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

function otable(t)
	for i,row in pairs(t) do
		for k,v in pairs(row) do
			print(i,k,v)
		end	
	end
end

function mtable_widths(t)
	for i,row in pairs(t.rows) do
		for k,v in pairs(row) do
			if string.len(v) > t.format[k].width then t.format[k].width = string.len(v) end
		end	
	end
end

--function mtable_remove_col(t,col)
--	for i,row in pairs(t.rows) do
--		row[col] = nil
--	end
--
--	t.columns[t.columnsid[col]] = nil
--	t.columnsid[col] = nil
--end

function mtable(s)
	local t = {}
	t.rows = {}
	t.columns = {}
	t.format = {}
	t.columnsid = {}

	for k,c in pairs(iarray(string.gmatch(s,"[^,]+"))) do
		t.format[c] = {}
		t.format[c].width = string.len(c)
		t.format[c].show = true
		t.columns[k] = c
		t.columnsid[c] = k
	end

	return t
end

function p_route()
	local rs = cmdo("sudo route -n")
	local t = mtable("destination,gateway,mask,flags,mss,window,irtt,interface")
	
	for l,line in pairs(iarray(string.gmatch(rs, "[^\n]+"))) do
		row = {}
		
		for f,v in pairs(iarray(string.gmatch(line, "%S+"))) do
			row[t.columns[f]] = v
		end
		t.rows[l] = row;
		if row["gateway"] == "IP" then t.rows[l] = nil end
		if row["gateway"] == "Gateway" then t.rows[l] = nil end
		
	end

	t.format["window"].show = false
	t.format["irtt"].show = false
	
	mtable_widths(t)
	return t
end

function p_connections()
	local rs = cmdo("sudo netstat -tupn")
	local t = mtable("proto,recv,send,local,remote,state,pid")
	
	for l,line in pairs(iarray(string.gmatch(rs, "[^\n]+"))) do
		row = {}
		
		for f,v in pairs(iarray(string.gmatch(line, "%S+"))) do
			if t.columns[f] ~= nil then 
				row[t.columns[f]] = v
			end
		end
		t.rows[l] = row;
		if row["proto"] == "Active" then t.rows[l] = nil end
		if row["proto"] == "Proto" then t.rows[l] = nil end
		if row["pid"] ~= nil and string.find(row["pid"],"chrome") then t.rows[l] = nil end
		if row["pid"] == "-" then t.rows[l] = nil end
	end
	
	t.format["recv"].show = false
	t.format["send"].show = false
	
	mtable_widths(t)
	return t
end

function p_ports(rs,proto)
	-- local rs = cmdo("sudo netstat -tulpn")
	local t = mtable("proto,recv,send,local,remote,pid")
	
	for l,line in pairs(iarray(string.gmatch(rs, "[^\n]+"))) do
		row = {}
		line = string.gsub(line,"LISTEN"," ")

		for f,v in pairs(iarray(string.gmatch(line, "%S+"))) do
			if t.columns[f] ~= nil then 
				row[t.columns[f]] = v
			end
		end

		t.rows[l] = row;
		if row["proto"] == "Active" then t.rows[l] = nil end
		if row["proto"] == "Proto" then t.rows[l] = nil end
		--if row["pid"] ~= nil and string.find(row["pid"],"chrome") then t.rows[l] = nil end
		--if row["pid"] == "-" then t.rows[l] = nil end

		if row["proto"] ~= proto then t.rows[l] = nil end

	end

	t.format["recv"].show = false
	t.format["send"].show = false
	t.format["remote"].show = false
	
	mtable_widths(t)

	--t.format["remote"].width
	return t
end


function conky_main()
	if conky_window == nil then
		return
	end

	--if tonumber(conky_parse('${updates}')) > tonumber(conky_parse('${update_interval}')) then
	if tonumber(conky_parse('${updates}')) > 5 then
		local cs = cairo_xlib_surface_create(
			conky_window.display,
			conky_window.drawable,
			conky_window.visual,
			conky_window.width,
			conky_window.height
		)

		local cr = cairo_create(cs)

		local leftx = 5

		local le,leB,mleY,prs

		


		--xdivider(cr,0,le.y+le.height+5,conky_window.width,le.y+le.height+5)

		le = xtable(cr,p_route(),leftx,100)
		--print(le.x,le.y,le.width,le.height)

		xdivider(cr,0,le.y+le.height+5,conky_window.width,le.y+le.height+5)

		le = xtable(cr,p_connections(),leftx,le.y+le.height+10)


		xdivider(cr,0,le.y+le.height+5,conky_window.width,le.y+le.height+5)

		prs = cmdo("sudo netstat -tulpn")

		le = xtable(cr,p_ports(prs,"tcp"),leftx,le.y+le.height+10)
		leB = xtable(cr,p_ports(prs,"udp"),le.x+le.width+10,le.y)

		mleY = math.max((le.y+le.height),(leB.y+leB.height))
		xdivider(cr,0,mleY+5,conky_window.width,mleY+5)

		le = xtable(cr,p_ports(prs,"tcp6"),leftx,mleY+10)
		leB = xtable(cr,p_ports(prs,"udp6"),leB.x,le.y)

		mleY = math.max((le.y+le.height),(leB.y+leB.height))
		xdivider(cr,0,mleY+5,conky_window.width,mleY+5)

		xprint(cr,(os.date("%Y-%m-%d %H:%M:%S")),le.x,mleY+20)


		cairo_destroy(cr)
		cairo_surface_destroy(cs)
		cr=nil
	end

end


