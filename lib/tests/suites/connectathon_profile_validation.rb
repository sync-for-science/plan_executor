module Crucible
  module Tests
    class ConnectathonProfileValidationTrackTest < BaseSuite

      def id
        'ConnectathonProfileValidationTrackTest'
      end

      def description
        'Connectathon Profile Validation Track Test focuses on validating observations against the general specification and a profile.'
      end

      def initialize(client1, client2=nil)
        super(client1, client2)
        @category = {id: 'connectathon', title: 'Connectathon'}
      end

      def setup
        @resources = Crucible::Generator::Resources.new

        @profile = @resources.track3_profile
        @profile.id = nil
        @profile.identifier = nil # clear the identifiers, in case the server checks for duplicates
        reply = @client.create @profile
        @profile.id = reply.id if !reply.id.nil?

        options = {
          id: @profile.id,
          resource: @profile.class,
          format: nil
        }
        @profile_url = @client.full_resource_url(options)
        @profile_url = reply.self_link if !reply.self_link.nil?

        @obs = @resources.track3_observations
        @obs.each do |x|
          x.id = nil
          x.identifier = nil # clear the identifiers, in case the server checks for duplicates
          x.meta = nil
        end
      end

      def teardown
        @client.destroy(FHIR::StructureDefinition, @profile.id) if !@profile.id.nil?
        # @obs.each do |x|
        #   @client.destroy(FHIR::Observation, x.id) if !x.id.nil?
        # end
      end

      #
      # Test if we can validate observations against the general specification.
      #
      test 'C8T3_2A','Validate Observations against the General Specification' do
        metadata {
          links 'http://wiki.hl7.org/index.php?title=FHIR_Connectathon_8#Track_3_-_Experimental:_Profiles_and_conformance'
          links "#{BASE_SPEC_LINK}/structuredefinition.html"
          links "#{BASE_SPEC_LINK}/observation.html"
          links "#{BASE_SPEC_LINK}/operation-resource-validate.html"
          requires resource: 'StructureDefinition', methods: ['create']
          validates resource: 'Observation', methods: ['$validate']
          validates profiles: ['validate-profile']
        }

        @obs.each do |x|
          reply = @client.validate(x)
          assert_response_ok(reply)
          if !reply.id.nil?
            assert( !reply.id.include?('_validate'), "Server created an Observation with the ID `_validate` rather than validate the resource.", reply.id)
          end
        end
      end

      #
      # Test if we can validate observations against a profile.
      #
      test 'C8T3_2B','Validate Observations against a Server-Side Profile' do
        metadata {
          links 'http://wiki.hl7.org/index.php?title=FHIR_Connectathon_8#Track_3_-_Experimental:_Profiles_and_conformance'
          links "#{BASE_SPEC_LINK}/structuredefinition.html"
          links "#{BASE_SPEC_LINK}/observation.html"
          links "#{BASE_SPEC_LINK}/operation-resource-validate.html"
          requires resource: 'StructureDefinition', methods: ['create']
          validates resource: 'Observation', methods: ['$validate']
          validates profiles: ['validate-profile']
        }
        skip if @profile.id.nil?
        # @profile_url = "http://hl7.org/fhir/StructureDefinition/#{resource_class.name.demodulize}" # the profile to validate with
        @obs.each do |x|
          x.meta = FHIR::Meta.new
          x.meta.profile = [ @profile_url ]
          reply = @client.validate(x,{profile_uri: @profile_url})
          assert_response_ok(reply)
          if !reply.id.nil?
            assert( !reply.id.include?('_validate'), "Server created an Observation with the ID `_validate` rather than validate the resource.", reply.id)
          end
        end
      end

    end
  end
end
