classdef DTDisplacementData < Specimen
    properties (SetAccess = private)
        m_displacementTroch;
        m_displacementHammer;
        m_time;
        m_timeStart;
        m_sampleRate;
        m_fileName;
    end % properties
    
    methods
        % Constructor
        function DTDD = DTDisplacementData(name,dxa,op,data)
            DTDD@Specimen(name,dxa,op,data);
        end
        
    end % methods
end % classdef
    