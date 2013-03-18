object @diputado

attributes :id, :nombre, :entidad, :distrito, :partido, :tipo_eleccion, :cabecera, :curul, :suplente, :onomastico, :email, :foto

child @comisiones => :comisiones do
    extends 'comisiones'
end
