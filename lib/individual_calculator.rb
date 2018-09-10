require 'json'

class IndividualCalculator
    def initialize(event_hash)
      @hash = event_hash
      ### TODO:  insert family vs individual for these sentences where there is family deductible vs individual
      #This will be based on the type of event that is passed into the Calculator
      @insight_dictionary = {  excluded_service: "This service is not included within your health plan. The cost is cost ",
                               other_covered_service: "This service is covered by you health plan, but we currently don't have pricing information on it.",
                               unknown_medical_event: "Sorry, this is a unknown medical event and we can't gather enough info to price this properly.",
                               out_of_pocket_hit: "Lucky you, you've spent cost, which is your out of pocket max (this is maxixum you will ever have to pay in a year). Yippy! You pay $0!",
                               family_out_of_pocket_max_hit: "Your family out of pocket max has been hit so you pay 0!",
                               deductible_applies_oopm_not_hit: "The deductible does not apply for this service. This means you don't have to have paid any money towards your deductible for this part of your plan to help you out. According to our estimates you will pay cost",
                               deductible_applies_oopm_hit:"You hit your out of pocket max for the year. This means you don't have to spend any more money so your cost is cost",
                               under_deductible_cost_over_deductible: "The cost for this service puts you over your deductible so you don't have to pay full price. Your estimated cost will be cost",
                               under_deductible_not_over_deductible: "You haven't met your deductible yet and the cost for this service does not put you over your deductible so you pay an estimated cost of cost",
                               over_deductible_not_over_oopm: "You have already met your deductible so your benefits are now kicked in on this service. You will have to pay an estimated cost of cost",
                               over_deductible_over_oopm: "The cost of this service will put you over your out of pocket max so you will have to pay an estimated cost of cost"
                             }
      @result = Result.new
    end
    attr_accessor :insight_dictionary, :result, :hash

    class Result
      attr_accessor :cost, :insight
    end

    def estimated_cost
      ### TODO: return @result objects instead of the cost values
      #Is the service excluded or not
      if @hash[:excluded_service]
        @result.insight = @insight_dictionary[:excluded_service]
        @result.cost = @hash[:cost_for_service]
      #If the service falls under one of the other covered services at the bottom of the sbc
      elsif @hash[:other_covered_service]
        @result.insight = @insight_dictionary[:other_covered_service]
        @result.cost = nil
      #Assuming the event object will be nil if the event is known in this case  we return nil
      elsif @hash[:unknown_medical_event]
        @result.insight = @nsight_dictionary[:unknown_medical_event]
        @result.cost = nil
      #make sure that the user has not already hit their out of pocket max if they have return 0
      elsif out_of_pocket_max_hit?
        @result.insight = @insight_dictionary[:out_of_pocket_hit]
        @result.cost = 0
      elsif !@hash[:deductible_applies] && !user_costs_over_oopm?
          @result.insight = @insight_dictionary[:deductible_applies_oopm_not_hit]
          @result.cost = benefit_cost
      #this runs if the costs end up putting the user over their oopm
      elsif user_costs_over_oopm? && !@hash[:deductible_applies]
          @result.insight = @insight_dictionary[:deductible_applies_oopm_hit]
          @result.cost = out_pocket_max_minus_out_of_pocket_current
      else
      #if the deductible does apply to this service
        @result = get_net_cost_deductible_applies
      end

      @result
    end

    private
    def out_of_pocket_max_hit?
       @hash[:out_of_pocket_current] >= @hash[:out_of_pocket_max]
    end

    ### TODO: Come up with a better name for this method
    def benefit_cost
      if @hash[:cost_type] =='coinsurance'
        @hash[:cost_value]*@hash[:cost_for_service]
      elsif @hash[:cost_type] == 'copay'
        @hash[:cost_value]
      elsif @hash[:cost_type] == 'copay_coinsurance'
        @hash[:cost_value] * @hash[:cost_for_service] + @hash[:cost_value_2]
      end
    end

    def out_of_pocket_current_benefit_cost
      @hash[:out_of_pocket_current] + benefit_cost
    end

    #only use when the deductible does not apply, or when the users deductible_current is over deductible_max Not to be used when the deductible does apply section
    def user_costs_over_oopm?
      out_of_pocket_current_benefit_cost >= @hash[:out_of_pocket_max]
    end

    def under_deductible?
      @hash[:deductible_current] < @hash[:deductible_max]
    end
    #This is the raw cost of the service plus the amount the user has spent towards their deductible
    def raw_cost_plus_deductible_current
      @hash[:cost_for_service] + @hash[:deductible_current]
    end

    def out_pocket_max_minus_out_of_pocket_current
      @hash[:out_of_pocket_max] - @hash[:out_of_pocket_current]
    end

    def deductible_remaining
      ##this if statement should never be called because before calling this function it is checked to see if the user is under their deductible
      #just for safety if something competely breaks
      if @hash[:deductible_current] > @hash[:deductible_max]
        0
      else
        @hash[:deductible_max] - @hash[:deductible_current]
      end
    end

    def current_deductible_plus_cost_over_oopm?
      #this kicks in if the cost of the service plus the current out of pocket max exeeds the out of pocket max
      #makes sure that the user does not pay over their out of pocket max
      if @result.cost + @hash[:out_of_pocket_current] > @hash[:out_of_pocket_max]
        @result.insight = @insight_dictionary[:over_deductible_over_oopm]
        @result.cost = out_pocket_max_minus_out_of_pocket_current
      end
    end

    #to be used in the get_net_cost_deductible_applies function only
    def get_cost_value
      deductible_overage =  @hash[:cost_for_service] - deductible_remaining
      if @hash[:cost_type] == 'coinsurance'
        #deductible_remaining + (@hash.cost_value * deductible_overage)
        ### TODO:  make sure this is right (pretty sure it is)
        # if the raw cost of the service puts the user into the decutible range then they automatically get the decuctible cost
        @hash[:cost_value] * @hash[:cost_for_service]
      ### TODO:  Add other options besides coinsurance and copay
      elsif @hash[:cost_type] == 'copay'
        #deductible_remaining + @hash.cost_value
        ### TODO:  talked about this case with anthony and he said if you hit the decutible with the raw cost of the service you only have to pay the copay
        @hash[:cost_value]
      elsif @hash[:cost_type] == 'copay_coinsurance'
        @hash[:cost_type] * @hash[:cost_for_service] + @hash[:cost_type_2]
      elsif @hash[:cost_type] =='nocharge'
        0
      elsif @hash[:cost_type] == 'not_covered'
        @hash[:cost_for_service]
      end
    end

    #this function is called at the end after all of the other condition has been checked.
    def get_net_cost_deductible_applies
      if under_deductible?
        # kick in benefits if the cost for the service exeeds that of the person @hash.deductible_current
        if raw_cost_plus_deductible_current >= @hash[:deductible_max]
          @result.insight =@insight_dictionary[:under_deductible_cost_over_deductible]
          @result.cost = get_cost_value
        else
          @result.insight = @insight_dictionary[:under_deductible_not_over_deductible]
          @result.cost = @hash[:cost_for_service]
        end
      # works when deductible spent is in between the deductible and the out of pocket max
      else
        @result.insight = @insight_dictionary[:over_deductible_not_over_oopm]
        @result.cost = benefit_cost
      end
      current_deductible_plus_cost_over_oopm?
      return @result
    end

  end
