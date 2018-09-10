require 'sinatra'
require 'json'
require './individual_calculator'
require './family_calculator'
###### Sinatra Part ######

set :port, 8080
set :environment, :production

post '/calc' do
  return_message = {}
  if params.has_key?('cost_value') &&
		params.has_key?('unknown_medical_event') &&
		params.has_key?('other_covered_service') &&
		params.has_key?('excluded_service') &&
		params.has_key?('cost_type') &&
		params.has_key?('deductible_applies') &&
		params.has_key?('cost_for_service') &&
		params.has_key?('out_of_pocket_max') &&
		params.has_key?('out_of_pocket_current') &&
		params.has_key?('deductible_max') &&
		params.has_key?('deductible_current')
	  calc = IndividualCalculator.new({cost_value: params[:cost_value].to_i,
																		 unknown_medical_event: params[:unknown_medical_event],
																		 other_covered_service: params[:other_covered_service],
																		 excluded_service: params[:excluded_service],
																		 cost_type: params[:cost_type].to_s,
																		 deductible_applies: params[:deductible_applies],
																		 cost_for_service: params[:cost_for_service].to_i,
																		 out_of_pocket_max: params[:out_of_pocket_max].to_i,
																		 out_of_pocket_current: params[:out_of_pocket_current].to_i,
																		 deductible_max: params[:deductible_max].to_i,
																		 deductible_current: params[:deductible_current].to_i})
    result = calc.estimated_cost
    if result.class == IndividualCalculator::Result
      return_message[:status] = 'success'
      return_message[:cost] = result.cost
    else
      return_message[:status] = 'Sorry - some informations was missing that is required to make an accurate estimate for the cost'
      return_message[:cost] = []
    end
  end
  return_message.to_json
end


post '/familycalc' do
  return_message = {}
  if params.has_key?('cost_value') &&
		params.has_key?('unknown_medical_event') &&
		params.has_key?('other_covered_service') &&
		params.has_key?('excluded_service') &&
		params.has_key?('cost_type') &&
		params.has_key?('deductible_applies') &&
		params.has_key?('cost_for_service') &&
		params.has_key?('out_of_pocket_max') &&
		params.has_key?('out_of_pocket_current') &&
		params.has_key?('deductible_max') &&
		params.has_key?('deductible_current')
	  calc = FamilyCalculator.new({cost_value: params[:cost_value].to_i,
																		 unknown_medical_event: params[:unknown_medical_event],
																		 other_covered_service: params[:other_covered_service],
																		 excluded_service: params[:excluded_service],
																		 cost_type: params[:cost_type].to_s,
																		 deductible_applies: params[:deductible_applies],
																		 cost_for_service: params[:cost_for_service].to_i,
																		 out_of_pocket_max: params[:out_of_pocket_max].to_i,
																		 out_of_pocket_current: params[:out_of_pocket_current].to_i,
																		 deductible_max: params[:deductible_max].to_i,
																		 deductible_current: params[:deductible_current].to_i},

                                     {cost_value: params[:cost_value].to_i,
 																		 unknown_medical_event: params[:unknown_medical_event],
 																		 other_covered_service: params[:other_covered_service],
 																		 excluded_service: params[:excluded_service],
 																		 cost_type: params[:cost_type].to_s,
 																		 deductible_applies: params[:deductible_applies],
 																		 cost_for_service: params[:cost_for_service].to_i,
 																		 out_of_pocket_max: params[:out_of_pocket_max].to_i,
 																		 out_of_pocket_current: params[:out_of_pocket_current].to_i,
 																		 deductible_max: params[:deductible_max].to_i,
 																		 deductible_current: params[:deductible_current].to_i})
    result = calc.estimated_cost
    if result.class == IndividualCalculator::Result
      return_message[:status] = 'success'
      return_message[:cost] = result.cost
    else
      return_message[:status] = 'Sorry - some informations was missing that is required to make an accurate estimate for the cost'
      return_message[:cost] = []
    end
  end
  return_message.to_json
end
