require './individual_calculator'
class FamilyCalculator
      def initialize(event_hash,fam_event_hash)
        @event_hash = event_hash
        @fam_event_hash = fam_event_hash
        @global_insight_dictionary = {
                                 family_out_of_pocket_max_hit: "Your family out of pocket max has been hit so you pay 0!"
                               }
        @result = Result.new
      end

      class Result
        attr_accessor :cost, :insight
      end

      def estimated_cost
        if family_out_of_pocket_max_hit?
          @result.insight = @global_insight_dictionary[:family_out_of_pocket_max_hit]
          @result.cost = 0
        else
          if family_deductible_greater_than_yours?
            @result = IndividualCalculator.new(@event_hash).estimated_cost
          else
            @result = IndividualCalculator.new(@fam_event_hash).estimated_cost
         end
        end
        @result
      end

      private
      #checks to see what deductible the user is closer to the families or their own, that decides when it should kick in.
      def family_deductible_greater_than_yours?
        @fam_event_hash[:deductible_max] - @fam_event_hash[:deductible_current] >= @event_hash[:deductible_max] - @event_hash[:deductible_current]
      end

      def out_of_pocket_max_hit?
         @event_hash[:out_of_pocket_current] >= @event_hash[:out_of_pocket_max]
      end

      def family_out_of_pocket_max_hit?
        @fam_event_hash[:out_of_pocket_current] >= @fam_event_hash[:out_of_pocket_max]
      end
end
