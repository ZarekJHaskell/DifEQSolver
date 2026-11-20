clear all;
clc;
clear vars;
%----------------------Data storage and simplification---------------------
function [struct] = convert(struct) %beginning of the function junction 
    if strcmp(struct.type,  'rectangular')
        struct.theta = atan2(struct.imag, struct.real); %auto arranges quadrants and handles division by zero
        struct.mag = sqrt(struct.real^2+struct.imag^2);
        struct.real = 0;
        struct.imag = 0;
        struct.type = 'exponential'; 
    else
        struct.real = struct.mag*cos(struct.theta); %reassigning magnitude to real component
        struct.imag = struct.mag*sin(struct.theta); %reassigning magnitude to imaginary component
        struct.mag = 0;
        struct.theta = 0;
        struct.type = 'rectangular';
    end  
    if abs(struct.real) < 0.000000001 %filter out rounding errors in conversions
        struct.real = 0;
    elseif abs(struct.imag) < 0.000000001
        struct.imag = 0;
    end
end
function[outputstruct] = supersimplify(equation,usertype)
    function [costring, coefficientside] = search(direction, string, startingindex) %searches ahead or behind to store the coefficient
        sign = ""; % determine the sign in front
        costring = "";
       
        if direction == '-'
            increment = -1; %if moving left start at the index before j
        else
            increment = 1;%if moving right start at the index after j
        end
        startingindex = startingindex + increment; %move off of j or e or operators in corresponding direction
        while string(startingindex) == ')'
            startingindex= startingindex + increment; %shifts infinitely until it no longer starts at ')' this is for real searching
        end
        if direction == '+' && startingindex ~= 2 % if the negative is on the other side add it into the right coef
            if string(startingindex - 2) == '-'
                sign = '-';
            end
        end
        while string(startingindex) ~= '+' && string(startingindex) ~= '*' && string(startingindex) ~= '-' && string(startingindex) ~= '/' && string(startingindex) ~= '^' && string(startingindex)~= '(' && string(startingindex) ~= ')' && ~isletter(string(startingindex)) %find the coefficient
            if direction == '-'
                costring = string(startingindex)+ costring; %dynamic string collection
            else
                costring = costring + (string(startingindex)); %store in the positive direction
            end
            if startingindex~=1 && startingindex ~=strlength(string) %no index out of bound errors
                startingindex = startingindex + increment;
            else
                break
            end
            if direction == '-' && string(startingindex) == '-' %only add a negative if its in front of the value
                sign = '-';
            end
        end
        if strcmp(costring, '') %empty coefficient edge case
            costring = costring + '1';
            coefficientside = '-';
        else
            
            coefficientside = "+";
        end
        costring = str2double(sign+costring); %combine the sign and the value into a double
    end
       
    function[struct] = findco(struct,string,startindex,type)%look left and right
            if startindex == 1
               [struct.(type)] = search('+',string,startindex); %struct.specifiedType will become the value of search in the specified direction
                    
            elseif startindex == strlength(string)
                [struct.(type)] = search('-',string,startindex);
            else
                [struct.(type), codirection] = search('+',string,startindex); %return value from the left or right
                if strcmp(codirection,'-') && struct.(type) ~= -1 %struct.type will only be negative if there was a negative side on the left meaning no coefficient besides -1
                    [struct.(type)] = search('-',string,startindex);
                end
            end
    end
    exponential = false; %state flag for exponential
    if strcmpi(usertype,'r') %case insensitive shorthand for both forms
        usertype = 'rectangular';
    elseif strcmp(usertype, 'e')
        usertype = 'exponential';
    end
    if strcmp(equation(1), '-') %appended to beginning of string to handle unary inputs
        equation = insertBefore(equation,1,'0j');
    end
    positions = []; %position within the string
    structinposition = []; % label of structure at that position
    operators = strings(0); %returns the operators between the values
    substring = "";
    structcount = 1;
    priority = 0; %keeps track of values inside of parenthesis
    struct(structcount) = structbuilder();
    equation = strrep(equation,'pi',num2str(pi)); %very low level built in program to replace pi with actual value
    equation = strrep(equation, ' ', '');
    elist = strfind(equation, 'e'); %All indexes of e
    jlist = strfind(equation, 'j');% All indexes of j
    function[position] = findposition(list, i) %goes backwards through the index string until it finds a value at an index before the operator
        for y = length(list):-1:1
            if list(y) < i
                position = list(y);
                break
            end
        end
    end
    function[substring,structinposition,positions,operators] = modplacements(list,i,structinposition,positions,operators,structcount, equation) %adjust all of the position arrays for Structs and operators in the equation string
        structinposition(structcount) = structcount;
        positions(structcount) = findposition(list,i);
        if i ~= strlength(equation)
            operators(end+1) = equation(i);
        end
        substring =""; % reset substring
    end
    equation = append(equation,'+'); %helps the loop create a substring for the last term
    for i = 1:1:strlength(equation) %big loop collects all data filln up structs
        if equation(i) == '(' && exponential == false %tracks
            priority = priority +1;
        end
        if equation(i) == "/" && exponential == true || equation(i) == "*" && exponential == true
            leftside = search("-",equation,i); %find the left of the operator
            rightside = search("+",equation,i);%find the value right of the operator
            if equation(i) == "/" %divide
                struct(structcount).theta = leftside/rightside;
            elseif equation(i) == "*" %multiply
                struct(structcount).theta = leftside*rightside;
            end
        elseif equation(i) ~= "+" && equation(i) ~= "-" && equation(i) ~= "*" && equation(i) ~= "/" % add the character to the substring
            substring = substring + equation(i);
            if equation(i) == 'e' %flip on the exponential boolean
                exponential = true;
            elseif equation(i) == ")"
                if exponential ~= true
                    priority = priority-1; %last value inside parenthesis or not inside parenthesis
                end
                exponential = false; %flip it off
            end
        elseif equation(i) == "-" && i == 1
            substring = "-" + substring;
        elseif  equation(i) == '-' && exponential == true
            substring = substring + '-';
            continue
        else
            if i ~= strlength(equation) && strcmp(equation(i),'-')
                if strcmp(equation(i+1),'(')
                    
                    struct(structcount).sub = true; %helps clear up an error with subtracting an expression in parenthesis
                end
            end
            struct(structcount).priority = priority; %assign each struct priority based on parenthesis
            if contains(substring, 'e') % collect the magnitude and theta
                struct(structcount+1) = structbuilder();
                if struct(structcount).theta == 0
                    struct(structcount) = findco(struct(structcount), equation, findposition(jlist,i),"theta");
                end
                struct(structcount).type = 'exponential';
                [substring,structinposition,positions,operators]=modplacements(elist,i,structinposition,positions,operators,structcount,equation);
                struct(structcount) = findco(struct(structcount), equation, findposition(elist,i),"mag");
                structcount = structcount +1;
            elseif contains(substring, 'j') % collect the imaginary component
                struct(structcount).type = 'rectangular';
                [substring,structinposition,positions,operators]=modplacements(jlist,i,structinposition,positions,operators,structcount,equation);
                struct(structcount) =findco(struct(structcount),equation, findposition(jlist,i),"imag");
                struct(structcount) = convert(struct(structcount));
                structcount = structcount +1;
                struct(structcount) = structbuilder();
            else % collect the real component
                struct(structcount+1) = structbuilder();
                struct(structcount).type = 'rectangular';
                struct(structcount).real = search('-', equation,i);
                struct(structcount) = convert(struct(structcount));
                substring = "";
                structinposition(structcount) = structcount;
                if i ~= strlength(equation)
                    operators(end+1) = equation(i);
                end
                %disp(struct(structcount))
                %disp(structinposition)
                structcount=structcount+1;
            end
        end
    end
    oper = ['/','*','+','-']; %searches the first two indexes then uses the last two in the second loop
    currentpriority = 0; % maximum priority eventually moves down to 0
    for i = 1:1:structcount-1
        if struct(i).priority >  currentpriority
            currentpriority = struct(i).priority;
        end
    end
    function[structtwo] = simplify(operator, struct, structtwo) %handles solving
        if strcmp(operator, '*') || strcmp(operator, '/')
            if ~strcmp(struct.type , 'exponential') %for mult and div need exponential form
                struct=convert(struct);
            end
            if ~strcmp(structtwo.type , 'exponential')
                structtwo = convert(structtwo);
            end
            if strcmp(operator,'*') %multiplication
                structtwo.theta = struct.theta + structtwo.theta;
                structtwo.mag = struct.mag * structtwo.mag;
            else %division
                structtwo.theta = struct.theta - structtwo.theta;
                structtwo.mag = struct.mag / structtwo.mag;
            end
        else %adding and subtracting
            if ~strcmp(structtwo.type, 'rectangular')
                structtwo = convert(structtwo);
            end
            if ~strcmp(struct.type, 'rectangular')
                struct = convert(struct);
            end
            if strcmp(operator, '+') %adding
                structtwo.real = struct.real + structtwo.real;
            else
                if struct.sub == 0 %Adding based on outside parenthesis sign
                    structtwo.real = struct.real + structtwo.real;
                else
                    structtwo.real = struct.real - structtwo.real;
                end
            end
            if struct.sub == 0
                structtwo.imag = struct.imag + structtwo.imag; %if the negative is not followed by parenthesis
            else
                structtwo.imag = struct.imag - structtwo.imag;
            end
        end
    end
    w=1;
    while length(structinposition) > 1 % continues until completely simplified
        for k = 1:2:3    % once loop is finished it has checked for each operator for every index of structinposition
            while w <= length(structinposition)-1 %goes through each struct
                if struct(w).priority == currentpriority &&( strcmp(oper(k),operators(w)) || strcmp(oper(k+1), operators(w)))%triggers when equal to one of two current indexes of oper                
                    struct(w+1) = simplify(operators(w),struct(w),struct(w+1)); %second struct now inherits the new evaluated properties
                    struct(w) = []; %clear old struct
                    operators(w) = []; %eliminate operator to avoid double counting
                    structinposition(w) = []; %eliminate placement of struct in the position array
                    w=w-1; % w needs to align with the shift
                end
                w=w+1; 
            
            end
            w=1; % w needs to reset for x iteration of while loop
        end
        currentpriority = currentpriority -1; % reduces current priority by one
    end
    struct(1).priority = 0;
    if ~strcmp(struct(1).type, usertype)
        struct(1) = convert(struct(1));
    end
    outputstruct = struct(1);
end
%------------------------------------MatrixMode----------------------------

function [struct] = structbuilder() %fields for each struct
    struct.type = ''; %exponential or rectangular
    struct.imag = 0; %imaginary
    struct.real = 0; %real
    struct.theta = 0; %angle of exponential form
    struct.mag = 0; %magnitude of exponential form
    struct.priority = 0;
    struct.sub = false;
end
for i = 1:1:12 %initialize 12 structs to fill the matrix
    struct(i) = structbuilder();
end
matrixdata = [struct(1),struct(2),struct(3),struct(4);struct(5),struct(6),struct(7),struct(8); struct(9),struct(10),struct(11),struct(12)]; %struct matrix
function [matrix,column] = findvalues(string, matrix,row) % goes through the row string and assigns each to their respected indexes inside of matrix data
    currentval = "";
    column = 1;
    for y = 1:1:strlength(string)
        if strcmp(string(y),',')
            matrix(row,column) = supersimplify(char(currentval),'e'); %sets the simplified value of the substring into the matrix in exponential form
            currentval = "";
            column = column +1;
        else
            currentval =  currentval + string(y);
        end
    end
    matrix(row,column) = supersimplify(char(currentval),'e');
end
columncount = 0;
fprintf('Input the coefficients for each variable then the equivalent value all seperated by commas \n')
variablenames = input('Insert variable names in order of column: ','s'); %breaks down the corresponding variables to each column of the matrix
variablearray = ["","",""];
variablestring = "";
countindex = 1;
for q = 1:1:strlength(variablenames)
    if strcmp(variablenames(q), ',')
        variablearray(countindex) = variablestring;
        variablestring ="";
        countindex=countindex+1;
    else
        variablestring = variablestring + variablenames(q);
    end
end
variablearray(countindex) = variablestring;
for p = 1:1:3 %maximum of 3 input
    row = input('enter the row seperated by commas: ','s');
    if strcmp(row,'0')
        if p < 2 %tried making a small matrix, needs a 2*2 or 3*3
            error('Make that matrix bigger man')
        else
            break
        end
    end
    [matrixdata, column] = findvalues(row,matrixdata,p);
    if column > columncount
        columncount = column;
    end
    if p >= columncount
        error('incorrect matrix sizing')
    end
end
if columncount <= 2 || columncount >4
    error('Incorrect matrix size!')
elseif columncount == 3 % 2*2 matrix
    %matrixdata = [struct(1),struct(2),struct(3),struct(4);struct(5),struct(6),struct(7),struct(8); struct(9),struct(10),struct(11),struct(12)]; %struct matrix
    multbymag = structbuilder();
    multbymagexpression = sprintf('1/(%g*e^(%gj)*%ge^(%gj)-%ge^(%gj)*%ge^(%gj))',matrixdata(1,1).mag,matrixdata(1,1).theta,matrixdata(2,2).mag,matrixdata(2,2).theta,matrixdata(2,1).mag,matrixdata(2,1).theta,matrixdata(1,2).mag,matrixdata(1,2).theta);
    multbymag = supersimplify(multbymagexpression,'e');
    if multbymag.mag == 0
        error('Infinite solutions or no solution')
    end
    inversematrixdata = [matrixdata(2,2),matrixdata(1,2),matrixdata(2,1), matrixdata(1,1)]; % a and d are flipped
    inversematrixdata(2).theta = inversematrixdata(2).theta + pi;
    inversematrixdata(3).theta = inversematrixdata(3).theta + pi; % b and c are negative
    solutiononeexpression = sprintf('(%ge^(%gj)*%ge^(%gj)+%ge^(%gj)*%ge^(%gj))*%ge^(%gj)', inversematrixdata(1).mag,inversematrixdata(1).theta,matrixdata(1,3).mag,matrixdata(1,3).theta,inversematrixdata(2).mag,inversematrixdata(2).theta,matrixdata(2,3).mag,matrixdata(2,3).theta,multbymag.mag,multbymag.theta);
    solutionone = supersimplify(solutiononeexpression,'e');
    solutiontwoexpression = sprintf('(%ge^(%gj)*%ge^(%gj)+%ge^(%gj)*%ge^(%gj))*%ge^(%gj)', inversematrixdata(3).mag,inversematrixdata(3).theta,matrixdata(1,3).mag,matrixdata(1,3).theta,inversematrixdata(4).mag,inversematrixdata(4).theta,matrixdata(2,3).mag,matrixdata(2,3).theta,multbymag.mag,multbymag.theta);
    solutiontwo = supersimplify(solutiontwoexpression,'e');
    fprintf('%s is ',variablearray(1))
    disp(solutionone)
    fprintf('%s is ',variablearray(2))
    disp(solutiontwo)
else
    fprintf('3*3')
end

