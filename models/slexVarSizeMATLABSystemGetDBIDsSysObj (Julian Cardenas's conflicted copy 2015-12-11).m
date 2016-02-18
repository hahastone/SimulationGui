classdef slexVarSizeMATLABSystemGetDBIDsSysObj < matlab.System & matlab.system.mixin.Propagates
%slexVarSizeMATLABSystemGetDBIDsSysObj Find input elements that satisfy the given condition.
%     The condition is specified in the block dialog. Both outputs 
%     are variable-sized vectors.
%

%#codegen
% Copyright 2013 The MathWorks, Inc.

properties (Nontunable)
    % db_name Database
    db_name = 'WaterHeaters';
    % db_username user
    db_username = 'sw_waterheaters';
    % Condition Search pattern
    Condition = ['%' datestr(now,'yyyymmdd') '%'];
end

properties
   % db_password password
   db_password ='unb.sql.2015';
   % N maximum number of units
   N = 100;
end

properties (Constant, Hidden)
  db_nameSet = matlab.system.StringSet({...
    'WaterHeaters', ...
    'HeatinUnits', ...
    'powerMeters'});
  db_usernameSet = matlab.system.StringSet({...
    'sw_waterheaters', ...
    'sw_ETS', ...
    'se_powermeters'});
  db_passwordSet = matlab.system.StringSet({...
    'unb.sql.2015', ...
    'sql.2015', ...
    'unb.2015'});
end

properties (Access = private)
    unitIDs = 0;
end

  methods
    function this = slexVarSizeMATLABSystemGetDBIDsSysObj(varargin)
        setProperties(this, nargin, varargin{:});
    end
  end
  
  methods(Static, Access=protected)
      
      function header = getHeaderImpl
          header = matlab.system.display.Header(...
              'slexVarSizeMATLABSystemGetDBIDsSysObj', ...
              'Title', 'Load Simulation access parameters');
      end
      
      function groups = getPropertyGroupsImpl
          firstGroup = matlab.system.display.SectionGroup(...
              'Title', 'Select', ...
              'PropertyList', {'Condition', 'N'});
            
          secondGroup = matlab.system.display.SectionGroup(...
              'Title', 'Database', ...
              'PropertyList', {'db_name', 'db_username', 'db_password'});
            
          groups = [firstGroup, secondGroup];
      end
  
  end
    
  methods(Access=protected)

      function setupImpl(obj, ~, ~)
          login.username = obj.db_username;
          login.password = obj.db_password;
          
          
          conn = open_sql_conn(obj.db_name, login);
          
          if (isempty(conn))
              error('Database connection error.');
          end
          
          %% TO DO: too particular. More general code should be implemented here
          if (strcmpi('WaterHeaters',obj.db_name))
              id_column_name = 'WaterHeaterID';
              name_column_name = 'WaterHeaterName';
          end
          
          if (strcmpi('heatingUnits',obj.db_name))
              id_column_name = 'ETSID';
              name_column_name = 'ETSName';
          end
          
          if (strcmpi('powerMeters',obj.db_name))
              id_column_name = 'MeterID';
              name_column_name = 'MeterName';
          end
          
          %%
          obj.unitIDs = fetch(conn, [' SELECT TOP ' num2str(obj.N,'%d '), id_column_name...
              ,' FROM ', obj.db_name, ' WHERE ', name_column_name, ' LIKE ', '''' obj.Condition '''' ]);
          %Close database connection.
          close(conn);
          
          if (isempty(obj.unitIDs))
              error('No devices matched search criterium.');
          end
      end
      
      function [values, ids] = stepImpl(obj)
          ids = double(obj.unitIDs);
          values = zeros(size(ids));
      end
      
      function num = getNumInputsImpl(~)
          num = 0;
      end
    
      function num = getNumOutputsImpl(~)
          num = 2;
      end

      function icon = getIconImpl(obj)
          icon = sprintf('Simulation\n%s',obj.db_name);
      end
        
      function [name1, name2] = getOutputNamesImpl(~)
          name1 = 'Output';
          name2 = 'unitIDs';
      end
      
      function [sz1, sz2] = getOutputSizeImpl(obj)
          % Maximum length of linear indices and element vector is the
          % number of elements in the input
          sz1 = obj.N;
          sz2 = sz1;
      end
      
      function [fz1, fz2] = isOutputFixedSizeImpl(~)
          %Both outputs are always variable-sized
          fz1 = false;
          fz2 = false;
      end
      
      function [dt1, dt2] = getOutputDataTypeImpl(~)
          dt1 = 'double'; %Linear indices are always double values
          dt2 = 'double';
      end
      
      function [cp1, cp2] = isOutputComplexImpl(~)
          cp1 = false; %unit ids are always real values
          cp2 = false; % power values are always real
      end
      
  end
  
end
