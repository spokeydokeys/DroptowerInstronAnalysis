classdef Specimen < handle
    properties (SetAccess = private,Hidden = true)
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
            % gender is one of: 'm' or 'f' - use 'u' for unknown
            % age is a number in years - use 0 for unknown
            % height is a number in cm - use 0 for unknown
            % weight is a number in kg - use 0 for unknown
            % dxa is a structure with fields:
            %      'neck','troch','inter','total','wards'
            % op is one of:
            %      'normal','osteopenia','osteoporosis','unknown'
            % data is a structure of bools indicating what data with 
            % is available. It is comprised of the fields:
            %      'InstronDAQ','InstronDIC','DropTowerDAQ','DropTowerDisplacement','DropTowerDIC'
            %
            % Sp = Specimen([SpecimenName],[gender],[age],[height],[weight],[DXAValues],[OPStatus],[Data])
            SP.SetSpecimenName(name);
            SP.SetDXA(dxa);
            SP.SetOpStatus(op);
            SP.SetAge(age);
            SP.SetHeight(height);
            SP.SetWeight(weight);
            SP.SetGender(gender);
            SP.SetDataAvailable(data);
        end
        
        function SetSpecimenName(SP,name)
            % A function to set the specimen name.
            %
            % SP.SetSpecimenName(name)
            %
            if ~ischar(name)
                error('No specimen name given. Aborting.')
            end
            SP.m_specimenName = name;

        end
        
        function SetDXA(SP,dxa)
            % A function to set the specimen DXA structure in g/cm^2.
            % The structure must have fields:
            %   neck
            %   troch
            %   inter
            %   total
            %   wards
            %
            % SP.SetDXA(DXA)
            %
            if (~isfield(dxa,'neck') || ~isfield(dxa,'troch') || ~isfield(dxa,'inter') || ~isfield(dxa,'total') || ~isfield(dxa,'wards') )
                error('Specimen:dxaFault','Malformed DXA structure. Please check the DXA data for %s and retry. Aborting.\n',SP.m_specimenName);
            end
            SP.m_dxa = dxa;
        end
        
        function SetOpStatus(SP,op)
            % A function to set the osteoporosis state of the specimen.
            % The value must be one of:
            %   normal
            %   osteopenia
            %   osteoporosis
            %
            % SP.SetOpStatus(status)
            %
            if (~strcmp(op,'normal') && ~strcmp(op,'osteopenia') && ~strcmp(op,'osteoporosis') &&~strcmp(op,'unknown' ))
                error('Specimen:opFault','Invalid osteoporosis state specified. Please check the value for %s and retry. Aborting.\n',SP.m_specimenName);
            end
            SP.m_opStatus = op;
        end
        
        function SetAge(SP,age)
            % A function to set the age of the specimen donor in years.
            % The value must be numeric. Use 0 for unknown.
            %
            % SP.SetAge(age)
            %
            if (~isnumeric(age))
                error('Specimen:ageFault','A non-numeric age was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_age = age;
        end
        
        function SetHeight(SP,height)
            % A function to set the height of the specimen donor in cm.
            % The value must be numeric. Use 0 for unknown.
            %
            % SP.SetHeight(height)
            %
            if (~isnumeric(height))
                error('Specimen:heightFault','A non-numeric height was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_height = height;
        end
        
        function SetWeight(SP,weight)
            % A function to set the weight of the specimen donor in kg.
            % The value must be numeric. Use 0 for unknown.
            %
            % SP.SetWeight(weight)
            %
            if(~isnumeric(weight))
                error('Specimen:weightFault','A non-numeric weight was specified for %s.\n',SP.m_specimenName);
            end
            SP.m_weight = weight;
        end
        
        function SetGender(SP,gender)
            % A function to set the gender of the specimen donor. The
            % value must be one of:
            %   m
            %   f
            %
            % SP.SetGender(gender)
            %
            if (~strcmp(gender,'m') && ~strcmp(gender,'f') && ~strcmp(gender,'u'))
                error('Specimen:genderFault','An invalid gender was supplied for %s.\n',SP.m_specimenName);
            end
            SP.m_gender = gender;
        end
        
        function SetDataAvailable(SP,data)
            % A function to set the data available structure for the
            % specimen. The structure uses bools to indicated if a certain
            % type of data is available for analysis. The structure
            % must have fields:
            %   InstronDAQ
            %   InstronDIC
            %   DropTowerDAQ
            %   DropTowerDisplacement
            %   DropTowerDIC
            %
            % SP.SetDataAvailable(data)
            %
            if ( ~isfield(data,'InstronDAQ') || ~isfield(data,'InstronDIC') || ~isfield(data,'DropTowerDAQ') || ~isfield(data,'DropTowerDisplacement') || ~isfield(data,'DropTowerDIC') )
                error('Specimen:dataFault','Malformed data available structure. Please check the values for %s and retry.\n',SP.m_specimenName);
            end
            SP.m_dataAvailable  = data;
        end
        
        % get functions for each property
        function o = GetSpecimenName(SP)
            % A function to get the specimen name.
            %
            % Name = SP.GetSpecimenName()
            %
            o = SP.m_specimenName;
        end
        function o = GetDXA(SP)
            % A function to get the specimen DXA in g/cm^2. The structure
            % will have fields:
            %   neck
            %   troch
            %   inter
            %   total
            %   wards
            %
            % DXA = SP.GetDXA()
            %
            o = SP.m_dxa;
        end
        function o = GetOpStatus(SP)
            % A function to get the specimen osteoporosis state.
            %
            % OPStatus = SP.GetOpStatus()
            %
            o = SP.m_opStatus;
        end
        function o = GetAge(SP)
            % A function to get the specimen donor age in years.
            %
            % Age = SP.GetAge()
            %
            o = SP.m_age;
        end
        function o = GetHeight(SP)
            % A function to get the height of the specimen donor in cm.
            %
            % Height = SP.GetHeight()
            %
            o = SP.m_height;
        end
        function o = GetWeight(SP)
            % A function to get the weight of the specimen donor in kg.
            %
            % Weight = SP.GetWeight()
            %
            o = SP.m_weight;
        end
        function o = GetGender(SP)
            % A function to get the gender of the specimen donor. The
            % value will be one of:
            %   m
            %   f
            %
            % Gender = SP.GetGender()
            %
            o = SP.m_gender;
        end
        function o = GetDataAvailable(SP)
            % A function to get the data available structure. The structure
            % uses bools to indicate the availability of certain data
            % sources. The structure will have fields:
            %   InstronDAQ
            %   InstronDIC
            %   DropTowerDAQ
            %   DropTowerDisplacement
            %   DropTowerDIC
            %
            % Data = SP.GetDataAvailable()
            %
            o = SP.m_dataAvailable;
        end

        
        function PrintSelf(SP)
            % A function to print the state of the specimen object.
            %
            % SP.PrintSelf()
            %
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
