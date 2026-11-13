
clear all;
clc;
clear vars;
function [struct] = structbuilder() %fields for each struct
    struct.type = ''; %exponential or rectangular
    struct.imag = 0; %imaginary
    struct.real = 0; %real
    struct.theta = 0; %angle of exponential form
    struct.mag = 0; %magnitude of exponential form
    struct.priority = 0;
end
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
end
function [costring, coefficientside] = search(direction, string, startingindex) %searches ahead or behind to store the coefficient
    sign = ""; % determine the sign in front
    costring = "";
   
    if direction == '-'
        increment = -1; %if moving left start at the index before j
    else
        increment = 1;%if moving right start at the index after j
    end
    
    
    startingindex = startingindex + increment;
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
        if startingindex~=1 && startingindex ~=strlength(string)
            startingindex = startingindex + increment;
        else
            break
        end
        if direction == '-' && string(startingindex) == '-'
            sign = '-';
        end
    end
    if strcmp(costring, '') %empty coefficient edge case
        costring = costring + '1';
        coefficientside = '-';
    else
        
        coefficientside = "+";
    end
    costring = str2double(sign+costring);
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
exponential = false;
equation = input('Input Equation!: ','s'); %user input string
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
    disp(i)
    if equation(i) == '(' && exponential == false %tracks
        priority = priority +1;
        struct(structcount).priority = priority;
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
                struct(structcount).priority = priority;
            end
            exponential = false; %flip it off
        end
    elseif equation(i) == "-" && i == 1
        substring = "-" + substring;
    elseif  equation(i) == '-' && exponential == true
        substring = substring + '-';
        continue
    else
        if contains(substring, 'e') % collect the magnitude and theta
            if struct(structcount).theta == 0
                struct(structcount+1) = structbuilder();
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

        end
    end
end
for i = 1:1:structcount-1
    disp(i)
    disp(struct(i))
end
oper = ['/','*','+','-'];
currentpriority = 0;
for i = 1:1:structcount-1
    if struct(i).priority >  currentpriority
        currentpriority = struct(i).priority;
    end
end
function[structtwo] = simplify(operator, struct, structtwo)
    if strcmp(operator, '*') || strcmp(operator, '/')
        if ~strcmp(struct.type , 'exponential')
            struct=convert(struct);
        end
        if ~strcmp(structtwo.type , 'exponential')
            structtwo = convert(structtwo);
        end
        if strcmp(operator,'*') 
            structtwo.theta = struct.theta + structtwo.theta;
            structtwo.mag = struct.mag * structtwo.mag;
        else
            structtwo.theta = struct.theta - structtwo.theta;
            structtwo.mag = struct.mag / structtwo.mag;
        end
    else
        if ~strcmp(structtwo.type, 'rectangular')
            structtwo = convert(structtwo);
        end
        if ~strcmp(struct.type, 'rectangular')
            struct = convert(struct);
        end
        structtwo.real = struct.real + structtwo.real;
        structtwo.imag = struct.imag + structtwo.imag;
    end
end
w=1;
while length(structinposition) > 1 % continues until completely simplified
    for k = 1:2:3    % once loop is finished it has checked for each operator for every index of structinposition
        while w <= length(structinposition)-1 %goes through each struct
            if struct(w).priority == currentpriority &&( strcmp(oper(k),operators(w)) || strcmp(oper(k+1), operators(w)))                
                struct(w+1) = simplify(operators(w),struct(w),struct(w+1));
                struct(w) = [];
                operators(w) = [];
                structinposition(w) = [];
                w=w-1;
            end
            w=w+1;
        
        end
        w=1;
    end
    currentpriority = currentpriority -1; % reduces current priority by one
end
struct(1).priority = 0;
disp(struct(1))