$:.unshift File.join(File.dirname(__FILE__),'lib')

require 'rubygems' 
require 'sinatra'
require 'rabl'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'builder'
require 'nokogiri'
require 'open-uri'

require 'diputado'
require 'comision'
require 'iniciativa'
require 'proposicion'
require 'votacion'
require 'asistencia'
require 'comision_integrante'

Rabl.register!
Rabl.configure do |config|
    config.include_json_root = false
    config.include_child_root = false
end

before do
    content_type :json
end

get '/api/diputados' do
    part = nil
    @diputados = Array.new
    doc = Nokogiri::HTML(open('http://sitl.diputados.gob.mx/LXII_leg/listado_diputados_gpnp.php?tipot=TOTAL'))
    doc.css("table table")[1].css("tr").each do |tr|

    	if tr.css("img").first
	    	src = tr.css("img").first.attr("src")
	    	case src
	    	when 'images/pri01.png'
				part = 'PRI'
	    	when 'images/pan.png'
				part = 'PAN'
	    	when 'images/prd01.png'
				part = 'PRD'
	    	when 'images/logvrd.jpg'
				part = "PVEM"
	    	when 'images/logo_movimiento_ciudadano.png'
				part = "MC"
	    	when 'images/logpt.jpg'
				part = 'PT'
	    	when 'images/panal.gif'
				part = 'NA'
	    	end
		end

		if tr.css("a").first
		    @diputado = Diputado.new
		    @diputado.id = tr.at_css("a").attr("href").gsub("curricula.php?dipt=", '')
		    @diputado.nombre = tr.at_css("a").text.gsub(/^\d+\s/, '').squeeze(' ')
		    @diputado.entidad = tr.css("td")[1].text.squeeze(' ')
		    @diputado.distrito = tr.css("td")[2].text.squeeze(' ')
		    @diputado.partido = part
		    @diputados << @diputado
		end
    end 

    rabl :diputados
end


get '/api/diputado/:id' do
    doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/curricula.php?dipt=#{params[:id]}"))
    node = doc.css("table tr")[2].css("table")[1]
    
    src = node.css("tr").first.css("td")[1].css("img").first.attr("src")
    case src
    when 'images/pri01.png'
		pt = 'PRI'
    when 'images/pan.png'
    	pt = 'PAN'
    when 'images/prd01.png'
    	pt = 'PRD'
    when 'images/logvrd.jpg'
    	pt = "PVEM"
    when 'images/logo_movimiento_ciudadano.png'
    	pt = "MC"
    when 'images/logpt.jpg'
    	pt = 'PT'
    when 'images/panal.gif'
    	pt = 'NA'
    end

    @diputado = Diputado.new
    @diputado.id = params[:id]
    @diputado.partido = pt
    @diputado.foto = 'http://sitl.diputados.gob.mx/LXII_leg/' + node.css("tr").first.css("td").first.css("img").attr("src")
    @diputado.nombre = node.css("tr").first.css("span").text.strip
    @diputado.tipo_eleccion = node.css("tr")[1].text.split(':')[1].strip
    @diputado.entidad = node.css("tr")[2].text.split(':')[1].strip
    @diputado.distrito = node.css("tr")[3].text.split(':')[1].strip
    @diputado.cabecera = node.css("tr")[4].text.split(':')[1].strip
    @diputado.curul = node.css("tr")[5].text.split(':')[1].strip
    @diputado.suplente = node.css("tr")[6].text.split(':')[1].strip
    @diputado.onomastico = node.css("tr")[7].text.split(':')[1].strip
    @diputado.email = node.css("tr")[8].text.split(':')[1].strip
    
    @comisiones = Array.new

    node.css("a").each do |a|
	if a.attr("href").match(/^integrantes_de_comisionlxii\.php\?comt=\d+/)
	    @comision = Comision.new
	    @comision.id = a.attr("href").gsub("integrantes_de_comisionlxii.php?comt=", "")
	    @comision.nombre = a.text.strip
	    @comisiones << @comision
	end
    end

    rabl :diputado
end


get '/api/diputado/:id/iniciativas' do

    @iniciativas = Array.new

    for t in 1..6 do
	doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/iniciativas_por_pernplxii.php?iddipt=#{params[:id]}&pert=#{t}"))
	tds = doc.css("table")[1].css("td")
	
	i = 0
	begin
	    if tds[i].text.strip != 'INICIATIVA'
		@iniciativa = Iniciativa.new
		@iniciativa.nombre = tds[i].text.strip.squeeze(' ')
		@iniciativa.turno_comision = tds[i+1].text.strip.squeeze(' ')
		@iniciativa.sinopsis = tds[i+2].text.strip.squeeze(' ')
		@iniciativa.tramite = tds[i+3].text.strip.squeeze(' ')
		@iniciativas << @iniciativa
	    end
	    i += 4
	end while i < tds.length
    end

    rabl :iniciativas

end


get '/api/diputado/:id/proposiciones' do

    @proposiciones = Array.new

    for t in 1..6 do
		doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/proposiciones_por_pernplxii.php?iddipt=#{params[:id]}&pert=#{t}"))
		tds = doc.css("table")[1].css("td")
		
		i = 0
		begin
		    if !tds[i].text.strip.match(/^PROPOSICI/)
				@proposicion = Proposicion.new
				@proposicion.nombre = tds[i].text.strip.squeeze(' ')
				@proposicion.turno_comision = tds[i+1].text.strip.squeeze(' ')
				@proposicion.resolutivos_proponente = tds[i+2].text.strip.squeeze(' ')
				@proposicion.resolutivos_aprobados = tds[i+3].text.strip.squeeze(' ')
				@proposicion.tramite = tds[i+4].text.strip.squeeze(' ')
				@proposiciones << @proposicion
		    end
		    i += 5
		end while i < tds.length
    end

    rabl :proposiciones
end


get '/api/diputado/:id/votaciones' do
    fecha = nil
    @votaciones = Array.new

    for t in 1..6 do
		doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/votaciones_por_pernplxii.php?iddipt=#{params[:id]}&pert=#{t}"))
		trs = doc.css("table table")[1].css("tr")
		
		trs.each do |tr|
		    if tr.at_css("td.TitulosVerde")
				fecha = tr.at_css("td.TitulosVerde").text
		    end

		    if tr.css("td").length > 1
				@votacion = Votacion.new
				@votacion.fecha = fecha
				@votacion.titulo = tr.css("td")[1].text.strip.squeeze(' ')
				@votacion.voto = tr.css("td")[3].text.strip.squeeze(' ')
				@votaciones << @votacion
		    end
		end
    end

    rabl :votaciones
end


get '/api/diputado/:id/asistencias' do
    fecha = nil
    
    @asistencias = Array.new

    for t in 1..6 do
		doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/asistencias_por_pernplxii.php?iddipt=#{params[:id]}&pert=#{t}"))
		trs = doc.css("table table")[1].css("tr table")[2]
		
		trs.css("table table").each do |mes|
		    
			mes.css("td").each do |td|
				if td.at_css("span.TitulosVerde")
				    fecha = td.at_css("span.TitulosVerde").text
				end
				
				if td.attr("bgcolor") == '#D6E2E2'
				    @asistencia = Asistencia.new
				    @asistencia.fecha = fecha.strip.squeeze(' ')
				    @asistencia.dia = td.at_css("font").inner_html.split("<br>")[0].strip
				    @asistencia.status = td.at_css("font").inner_html.split("<br>")[1].strip
				    @asistencias << @asistencia
				end
		    end
		end
    end

    @asistenciasHash = Hash.new{|h, k| h[k] = []}
    @asistencias.each do |a|
    	@asistenciasHash[a.fecha] << a
    end

    require 'json'
    @asistenciasHash.to_json
    #rabl :asistencias
end


get '/api/comision/:id/integrantes' do
	cargo = nil
	@comision_integrantes = Array.new
	doc = Nokogiri::HTML(open("http://sitl.diputados.gob.mx/LXII_leg/integrantes_de_comisionlxii.php?comt=#{params[:id]}"))

	doc.css("table table")[1].css("tr").each do |tr|

		if tr.at_css("td.TitulosVerde")
		    cargo = tr.at_css("td.TitulosVerde").text
		end

		if tr.css("td").length > 3

			a = tr.css("td").first.at_css("a")

			if a and a.attr("href").match(/^curricula\.php\?dipt=\d+/)
				@comision_integrante = ComisionIntegrante.new
				@comision_integrante.id = a.attr("href").gsub('curricula.php?dipt=', '')
				@comision_integrante.nombre = a.text.strip.squeeze(' ')
				@comision_integrante.partido = tr.css("td")[1].text.strip.squeeze(' ')
				@comision_integrante.entidad = tr.css("td")[2].text.strip.squeeze(' ')
				@comision_integrante.ubicacion = tr.css("td")[3].text.strip.squeeze(' ')
				@comision_integrante.extension = tr.css("td")[4].text.strip.squeeze(' ')
				@comision_integrante.cargo = cargo
			 	@comision_integrantes << @comision_integrante
			end

		end

	end

	rabl :comision_integrantes
end
