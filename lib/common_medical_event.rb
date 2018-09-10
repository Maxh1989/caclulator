
  # TODO: we need to figure out how we're handling individual vs. family,
  # so all of this is subject to change
class CommonMedicalEvent
    attr_reader :tracking_scope, :sbc, :hash
    def initialize(procedure, user_plan, tracking_scope = 'individual')
      @procedure = procedure
      @user_plan = user_plan
      @tracking_scope = tracking_scope
      @hash = {}
      # TODO: we may want to pass this in as an argument
      @sbc = Rules::Sbc.new(@user_plan.plan)
    end

    def deductible_current
      # TODO: we should be adding uniqueness constraints across user_plan_id,
      # tracking_scope, network_type, and accumulator_type. This will also
      # require an index across these for speed:
      #
      # https://stackoverflow.com/a/34425284cd
      #
      # This applies to all accumulators
      @deductible_current ||= deductible_accumulator.current
    end

    def deductible_max
      @deductibe_max ||= deductible_accumulator.max
    end

    def out_of_pocket_current
      @out_of_pocket_current ||= out_of_pocket_accumulator.current
    end

    def out_of_pocket_max
      @out_of_pocket_max ||= out_of_pocket_accumulator.max
    end

    def cost_for_service
      @cost_for_service ||= @procedure.cost
    end

    def benefit_details
      @benefit_details ||= @sbc.benefit_details_for_procedure(@procedure)
    end

    def deductible_applies?
      benefit_details.deductible?
    end

    def cost_value
      benefit_details.cost_value
    end

    def cost_type
      benefit_details.cost_type
    end

    def network_type
      @procedure.network_type
    end

    def excluded_service?
      benefit_details.excluded_service
    end

    def other_covered_service?
      benefit_details.other_covered
    end

    def unknown_medical_event?
      benefit_details.unknown_medical_event
    end

    def return_hash
      @hash = {unknown_medical_event: unknown_medical_event?,
                     other_covered_service: other_covered_service?,
                     excluded_service: excluded_service?,
                     network_type: network_type,
                     cost_type: cost_type,
                     cost_value: cost_value,
                     deductible_applies: deductible_applies?,
                     benefit_details: benefit_details,
                     cost_for_service: cost_for_service,
                     out_of_pocket_max: out_of_pocket_max,
                     out_of_pocket_current: out_of_pocket_current,
                     deductible_max: deductible_max,
                     deductible_current: deductible_current}
    end


    private

    def deductible_accumulator
      @deductible_accumulator ||= @user_plan.user_plan_accumulators
                                            .find_by(tracking_scope: tracking_scope,
                                                     network_type: network_type,
                                                     accumulator_type: 'deductible')
    end

    def out_of_pocket_accumulator
      @out_of_pocket_accumulator ||= @user_plan.user_plan_accumulators
                                               .find_by(tracking_scope: tracking_scope,
                                                        network_type: network_type,
                                                        accumulator_type: 'out_of_pocket')
    end



end
