classdef Specimen < handle
    properties (SetAccess = private)
        % immutables properties of each specimen
        m_specimenName;
        m_gender;
        m_dxa;
        m_opStatus;
        m_age;
        m_height;
        m_weight;
        m_dataAvailable;
        % these are bools to say if the data is available
    end
    methods
        function SP = Specimen(name,gender,age,height,weight,dxa,op,data)
            % The constructor takes the name, DXA values the osteoporosis
            % status and the available data as inputs.
            % name is a string
            % gender is one of: 'm' or 'f'
            % age is a number in years - use 0 for unknown
            % height is a number in cm - use 0 for unknown
            % weight is a number in kg - use 0 for unknown
            % dxa is a structure with fields:
            %      'neck','troch','inter','total','wards'
            % op is one of:
            %      'normal','osteopenia','osteoporosis'
            % data is a structure of bools indicating what data with 
            % is available. It is comprised of the fields:
            %      'InstronDAQ','InstronDIC','DropTowerDAQ','DropTowerDisplacement','DropTowerDIC'
            %
            % Sp = Specimen([SpecimenName],[age],[height],[weight],[DXAValues],[OPStatus])
            SP.SetSpecimenName(name);
            SP.SetDxa(dxa);
            SP.SetOp(op);
            SP.SetAge(age);
            SP.SetHeight(height);
            SP.SetWeight(weight);
            SP.SetGender(gender);
            SP.SetData(data);
        end
        
        function SetSpecimenName(SP,name)
            if ~ischar(name)
                error('No specimen name given. Aborting.')
            end
            SP.m_specimenName = name;

        end
        
        function SetDxa(SP,dxa)
            if (~isfield(dxa,'neck') || ~isfield(dxa,'troch') || ~isfield(dxa,'inter') || ~isfield(dxa,'total') || ~isfield(dxa,'wards') )
                error('Specimen:dxaFault','Malformed DXA structure. Please check the DXA data for %s and retry. Aborting.\n',SP.m_specimenName);
            end
            SP.m_dxa = dxa;
        end
        
        function SetOp(SP,op)
            if (~strcmp(op,'normal') && ~strcmp(op,'osteopenia') && ~strcmp(op,'osteoporosis') )
                error('Specimen:opFault','Invalid osteoporosis state specified. Please check the value for %s and retry. Aborting.\n',SP.m_specimenName);
            end
            SP.m_opStatus = op;
        end
        
        function SetAge(SP,age)
            if (~isnumeric(age))
                error('Specimen:ageFault','A non-numeric age was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_age = age;
        end
        
        function SetHeight(SP,height)
            if (~isnumeric(age))
                error('Specimen:heightFault','A non-numeric height was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_height = height;
        end
        
        function SetWeight(SP,weight)
            if(~isnumeric(age))
                error('Specimen:weightFault','A non-numeric weight was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_weight = weight;
        end
        
        function SetGender(SP,gender)
            if (~strcmp(gender,'m') || ~ strcmp(gender,'f'))
                error('Specimen:genderFault','An invalid gender was supplied for %s.\n',SP.m_specimenName);
            end
            SP.m_gender = gender;
        end
        
        function SetData(SP,data)
            if ( ~isfield(data,'InstronDAQ') || ~isfield(data,'InstronDIC') || ~isfield(data,'DropTowerDAQ') || ~isfield(data,'DropTowerDisplacement') || ~isfield(data,'DropTowerDIC') )
                error('Specimen:dataFault','Malformed data available structure. Please check the values for %s and retry.\n',SP.m_specimenName);
            end
            SP.m_dataAvailable  = data;
        end
        
        % get functions for each property
        function o = GetSpecimenName(SP)
            o = SP.m_specimenName;
        end
        function o = GetDXA(SP)
            o = SP.m_dxa;
        end
        function o = GetOpStatus(SP)
            o = SP.m_opStatus;
        end
        function o = GetAge(SP)
            o = SP.m_age;
        end
        function o = GetHeight(SP)
            o = SP.m_height;
        end
        function o = GetWeight(SP)
            o = SP.m_weight;
        end
        function o = GetGender(SP)
            o = SP.m_gender;
        end
        function o = GetDataAvailable(SP)
            o = SP.m_dataAvailable;
        end

        
        function PrintSelf(SP)
            fprintf(1,'\n%%%%%%%%%% Specimen Class Data %%%%%%%%%%\n');
            fprintf(1,'Specimen name: %s\n',SP.GetSpecimenName());
            fprintf(1,'Specimen dnoor gender: %s\n',SP.GetGender());
            fprintf(1,'Specimen donor age: %d years\n',SP.GetAge());
            fprintf(1,'Specimen donor height: %d cm\n',SP.GetHeight());
            fprintf(1,'Specimen donor weight: %0.4f kg\n',SP.GetWeight());
            dxaData = SP.GetDXA();
            fprintf(1,'Specimen DXA values (g/cm^2):\n\tNeck:  %f\n\tTroch: %f\n\tInter: %f\n\tTotal: %f\n\tWards: %f\n',dxaData.neck,dxaData.troch,dxaData.inter,dxaData.total,dxaData.wards);
            fprintf(1,'Specimen osteoporosis state: %s\n',SP.GetOpStatus());
            dataAva = SP.GetDataAvailable();
            fprintf(1,'Specimen data fields available:\n\tInstronDAQ:            %d\n\tInstronDIC:            %d\n\tDropTowerDAQ:          %d\n\tDropTowerDisplacement: %d\n\tDropTowerDIC:          %d\n',dataAva.InstronDAQ,dataAva.InstronDIC,dataAva.DropTowerDAQ,dataAva.DropTowerDisplacement,dataAva.DropTowerDIC);
        end
        
    end
end
