include DocumentParser
class RemoteCensusApi

  def call(document_type, document_number)
    response = nil
    get_document_number_variants(document_type, document_number).each do |variant|
      response = Response.new(get_response_body(document_type, variant))
      return response if response.valid?
    end
    response
  end

  class Response
    def initialize(body)
      @body = body
    end

    def extract_value(path_value)
      path = parse_path(path_value)
      return nil unless path.present?
      @body.dig(*path)
    end

    def valid?
      path_value = Setting["remote_census.response.valid"]
      extract_value(path_value).present?
    end

    def date_of_birth
      path_value = Setting["remote_census.response.date_of_birth"]
      str = extract_value(path_value)
      return nil unless str.present?
      day, month, year = str.match(/(\d\d?)\D(\d\d?)\D(\d\d\d?\d?)/)[1..3]
      return nil unless day.present? && month.present? && year.present?
      Time.zone.local(year.to_i, month.to_i, day.to_i).to_date
    end

    def postal_code
      path_value = Setting["remote_census.response.postal_code"]
      extract_value(path_value)
    end

    def district_code
      path_value = Setting["remote_census.response.district"]
      extract_value(path_value)
    end

    def gender
      path_value = Setting["remote_census.response.gender"]

      case extract_value(path_value)
      when "Varón"
        "male"
      when "Mujer"
        "female"
      end
    end

    def name
      path_value_name = Setting["remote_census.response.name"]
      path_value_surname = Setting["remote_census.response.surname"]

      "#{extract_value(path_value_name)} #{extract_value(path_value_surname)}"
    end

    def parse_path(path_value)
      path_value.split(".").map{ |section| section.to_sym } if path_value.present?
    end
  end

  private

    def get_response_body(document_type, document_number)
      if end_point_available?
        client.call(Setting["remote_census.request.method_name"].to_sym, message: request(document_type, document_number)).body
      else
        stubbed_response(document_type, document_number)
      end
    end

    def client
      @client = Savon.client(wsdl: Setting["remote_census.general.endpoint"])
    end

    def request(document_type, document_number)
      structure = eval(Setting["remote_census.request.structure"])

      fill_in(structure, Setting["remote_census.request.document_type"], document_type)
      fill_in(structure, Setting["remote_census.request.document_number"], document_number)

      structure
    end

    def fill_in(structure, path_value, value)
      path = parse_path(path_value)

      update_value(structure, path, value) if path.present?
    end

    def parse_path(path_value)
      path_value.split(".").map{ |section| section.to_sym } if path_value.present?
    end

    def update_value(structure, path, value)
      *path, final_key = path
      to_set = path.empty? ? structure : structure.dig(*path)

      return unless to_set
      to_set[final_key] = value
    end

    def end_point_available?
      Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?
    end

    def stubbed_response(document_type, document_number)
      if (document_number == "12345678Z" || document_number == "12345678Y") && document_type == "1"
        stubbed_valid_response
      else
        stubbed_invalid_response
      end
    end

    def stubbed_valid_response
      {
        get_habita_datos_response: {
          get_habita_datos_return: {
            datos_habitante: {
              item: {
                fecha_nacimiento_string: "31-12-1980",
                identificador_documento: "12345678Z",
                descripcion_sexo: "Varón",
                nombre: "José",
                apellido1: "García"
              }
            },
            datos_vivienda: {
              item: {
                codigo_postal: "28013",
                codigo_distrito: "01"
              }
            }
          }
        }
      }
    end

    def stubbed_invalid_response
      {get_habita_datos_response: {get_habita_datos_return: {datos_habitante: {}, datos_vivienda: {}}}}
    end

end
