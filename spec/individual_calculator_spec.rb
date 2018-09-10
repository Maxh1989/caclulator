
require 'individual_calculator.rb'
require 'common_medical_event.rb'
require 'csv'

describe IndividualCalculator do
  before(:each) do
  #  @event = double(CommonMedicalEvent)
    @calculator = IndividualCalculator.new(unknown_medical_event: false)
  end

  def stub_event(event, methods)
    methods.each do |method_name, return_value|
      allow(event).to receive(method_name).and_return(return_value)
    end
  end

  describe '#estimated_cost' do
    data = CSV.read(File.join('/home/max/Desktop/sinatra/', 'spec', 'support', 'individual_calc.csv'), { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
    hashed_data = data.map { |d| d.to_hash }

    hashed_data.each do |hash|
      context hash[:description] do
        before(:each) do
          puts hash[:excluded_service]
          data = {unknown_medical_event:  !hash[:unknown_medical_event].to_i.zero?,
                                other_covered_service: !hash[:other_covered_service].to_i.zero?,
                                excluded_service: !hash[:excluded_service].to_i.zero?,
                                network_type: "none",
                                cost_type: hash[:cost_type].to_s.gsub(" ",""),
                                cost_value: hash[:cost_value].to_f,
                                deductible_applies: !hash[:deductible_applies].to_i.zero?,
                                cost_for_service: hash[:cost_for_service],
                                out_of_pocket_max: hash[:out_of_pocket_max],
                                out_of_pocket_current:  hash[:out_of_pocket_current],
                                deductible_max: hash[:deductible_max],
                                deductible_current: hash[:deductible_current]}

          @calculator.hash = data
        end
        it 'should return the estimated cost' do
          expect(@calculator.estimated_cost.cost).to eq(hash[:expected_value])
        end
      end
    end
  end
end
