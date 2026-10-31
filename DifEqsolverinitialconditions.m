%x''+6E5*x'+8x=0
%for RLC make a calculator for the resonant frequency and the nebular
%frequency create a button that allows you to copy the parrallel RLC
%equation that can be placed inside the text field on the app
function [equationdata] = equationdatabuilder(type, rootone, roottwo, copart, rootpart)
    equationdata.type = type;
    equationdata.rootone = rootone;
    equationdata.roottwo = roottwo;
    equationdata.copart = copart;
    equationdata.rootpart=rootpart;
end
function [simplifiedans, startind, eval, coef] = searchback(string, startind) %used to simplify engineering/ scientific notation
    coef = "";
    eval = "";
    emarker = false;
    comarker = false;
    while string(startind) ~= "E" %find the 10^(.....
        eval = string(startind) + eval;
        if startind ~=1
            startind= startind -1;
        else
            break
        end
        if string(startind) == "-"
            emarker = true;
        end
    end
    startind=startind-1;
    while string(startind) ~= "-" && string(startind) ~= "+" && string(startind) ~= " "%find the coefficient
        coef = string(startind) + coef;
        if startind ~=1
            startind = startind-1;
        else
            break
        end
        if string(startind) == "-"
            comarker = true;
        end
    end
    if string(startind) == "+" % if it ends on a + i dont want to erase it
        startind = startind+1;
    end
    if emarker == true
        if comarker == true
        
            simplifiedans=num2str(-1*str2double(coef) * 10^(str2double(eval)), '%.15f');
        else
            simplifiedans=num2str(str2double(coef) * 10^(str2double(eval)), '%.15f');
        end
    else
        if comarker == true
            simplifiedans=num2str(-1*str2double(coef) * 10^(str2double(eval)), '%.15f');
        else
            simplifiedans=num2str(str2double(coef) * 10^(str2double(eval)), '%.15f');
        end
    end
end
function [refinedeq] = solvesystem(equationdata,init,initderiv) %take user input initial conditions and return the solved c1 and c2 equation 
    
    if strcmp(equationdata.type, 'complex')
        cone= init-equationdata.copart;
        ctwo= (initderiv-equationdata.rootpart*equationdata.copart-equationdata.rootone*cone)/equationdata.roottwo;
        refinedeq = sprintf('%ge^(%gt)cos(%gt)+%ge^(%gt)sin(%gt)+%ge^(%gt)',cone,equationdata.rootone,equationdata.roottwo,ctwo,equationdata.rootone,equationdata.roottwo,equationdata.copart,equationdata.rootpart);
    elseif strcmp(equationdata.type, 'distinct')
        ctwo = (equationdata.rootone*init-initderiv-equationdata.copart*(equationdata.rootone-equationdata.rootpart))/(equationdata.rootone-equationdata.roottwo);
        cone = init-equationdata.copart-ctwo;
        refinedeq = sprintf('%ge^(%gt)+%ge^(%gt)+%ge^(%gt)',cone,equationdata.rootone,ctwo, equationdata.roottwo, equationdata.copart, equationdata.rootpart);
    end
 
end
%add an engineering notation simplifier
%use the searchback method and replace the indexes of the old engineering
%notation with simplifiedans
de = input('Enter a homogeous differential equation(in terms of x or y): ', 's');
dowhat = input("Tell me what to do: ",'s');
keywords = ["solve","particular", "complete general", "general", "roots"];
keywordscontained = []; % indexes: 1= roots, 2= general, 3= complete general, 4 = particular 5=solve
for search = length(keywords):-1:1
    keywordscontained(-1*search+6) = contains(dowhat,keywords(search));
end
if count(dowhat,'general') == 1 && keywordscontained(3) == true
    keywordscontained(2) = false;
end
disp(keywordscontained)
xcindex = strfind(de,'='); %placement of equal sign
xc = de(1:xcindex-1); %characteristic equation as a string
if contains(xc, 'x') %did they use x or y?
    chosenvarname = 'x';
else
    chosenvarname = 'y';
end
xvalues = strfind(xc, chosenvarname); %all indexes of x
stringindexes = strfind(xc, "'"); %all index's of apostrophes
highestcount = 0; 
tally = 0;
for i = stringindexes(end):-1:1 %find the highest order
    if xc(i) ~= "'"
        tally = 0;
    else
        tally = tally+1; 
    end
    if tally > highestcount
        highestcount = tally;
    end
end 
xtracker = [0,0,0]; % count the amount of x'' (index3), x' (index2), and x(index1) to make sure there is no repeats
%index 3 = a or coefficient of x''
%index 2 = b or coefficient of x'
%index 1 = c or coefficient of x
coefficients = [0,0,0]; %coefficient values
if highestcount >=3 %they entered a higher than 2nd order DE!
    fprintf('I cant do all that pal\n')
end
coefficienttracker = 1; %separating the coefficients
%Assign the coefficients
j= xcindex - 1;
fprintf('%s',xc(end));
% 4x'' + 5x' + 4E6x

while j > 0  
    if xc(j) == " " %getting rid of filler
    elseif xc(j) == "*" % if there is a * i know there is scientific notation
        [newstring, indend, eval, coef] = searchback(xc,j-1);
        xc=eraseBetween(xc,indend, j);
        xc=insertAfter(xc, indend-1, newstring);
        disp(newstring)
        disp(eval)
        disp(coef)
        %x''+6E-5*x'+x=0
        %x''+0.00006x'+x=0
        %add to j the value of length of newstring subtracted by the length
        %of the old string which is j-indend
        %j = j+length(newstring)-(j-indend);
        j = length(newstring)+indend;
    elseif xc(j) == chosenvarname % the index = x/y
        tally = 0;
        base = 0;
        if j == 1 %if x of any kind is the last in the list the coefficient is 1
            coefficients(coefficienttracker) = 1;
        end
        if xc(j) == xc(end) && j == strlength(xc)
            xtracker(1) = xtracker(1)+1; %if x is the first thing to show up,add 1 to x
        else
            if xc(j+1) ~="'" %if no ' then its just x
                coefficienttracker = 1;
                xtracker(1) = xtracker(1)+1;
          
            end
        end

    elseif xc(j) == "'" 
        if xc(j-1) == "'" %'' means second order
            coefficienttracker = 3;
            j=j-1;
            xtracker(coefficienttracker) =xtracker(coefficienttracker)+1;%add 1 to x'''
        else
            coefficienttracker = 2;
            xtracker(coefficienttracker) =xtracker(coefficienttracker)+1;%add 1 to x''
        end
    elseif xc(j) == "."
        coefficients(coefficienttracker) = coefficients(coefficienttracker)*(10^(base*-1));
        base=0;
    elseif xc(j) ~= "+" && xc(j) ~="-" %this index is a number
        coefficients(coefficienttracker) = coefficients(coefficienttracker)+(10^base)*str2double(xc(j));
        base= base+1; %10^base is how I manage the place value of the coefficient
    elseif xc(j) == "-" || xc(j) == "+" %if any of the coefficients begin with - they are negative
        if coefficients(coefficienttracker) == 0
            coefficients(coefficienttracker) =1;
        end
        if xc(j) == "-" %current number is negative
            coefficients(coefficienttracker) = coefficients(coefficienttracker) * -1;
        %0.0001
        %0001
        %10^3 10^2 10^1 10^0
        end
        
    end
    j=j-1; % decrease from final x/y value to the start of the characteristic equation
end
if xtracker(1) >1 || xtracker(2) > 1 || xtracker(3) > 1
    error('You are already using a calculator and you are still too lazy to simplify the homogenous equation');
end
insidesqrt = coefficients(2)^2 - coefficients(3)*4*coefficients(1); %inside of sqrt in quad eq
negative = insidesqrt < 0;%if insidesqrt = negative then its complex
if negative == true
    insidesqrt= insidesqrt*-1;
    complexpart = sqrt(insidesqrt)/(2*coefficients(3));
end
rt = (-1*coefficients(1))/coefficients(2);%1st order root
realpart = -1*coefficients(2)/ ( 2* coefficients(3)); %left side of quad eq
rtone = realpart + sqrt(insidesqrt)/ (2*coefficients(3)); % }roots
rttwo = realpart - sqrt(insidesqrt)/ (2*coefficients(3)); % }
if keywordscontained(1) == true && highestcount == 1
    fprintf('The root is %g\n', rt);
elseif keywordscontained(1) == true && negative == true %printing the roots
    fprintf('The root for the characteristic equation is %g +or- %gi\n',realpart,complexpart);
elseif keywordscontained(1) == true && rtone ~= rttwo
    fprintf('The roots for the characteristic equation is %g and %g\n',rtone, rttwo);
elseif keywordscontained(1) == true 
    fprintf('The roots for the characteristic equation are both %g\n',rtone);
end
if highestcount == 2 && keywordscontained(2) == true
    if negative == true %if the inside of the sqrt negative = complex "i"
        fprintf("The general solution is: ");
        fprintf('e^(%gt)(C1cos(%gt)+C2sin(%gt))\n', realpart, complexpart, complexpart);%complex root gen solution
    else
        fprintf('The general solution is: ') 
        if rtone ~= rttwo
            fprintf('C1e^(%gt) + C2e^(%gt)\n',rtone, rttwo); %distinct real roots gen solution
        else
            fprintf('C1e^(%gt) + C2te^(%gt)\n',rtone, rttwo); %repeated real roots gen solution
        end
    end
elseif highestcount == 1 && keywordscontained(2) == true
    fprintf('The general Solution is C1e^(%gt)\n', rt); 
end 
%------------------End of characteristic equation solver-------------------

fx = de(xcindex+1:end);
%first working on real roots
nbase=0;
cotracker = 1;
tlocations = strfind(fx, "t");
if isempty(tlocations) == false
    covalue = false;
    covalues = [1];
    expvalues = [1];
    for joe = tlocations(end)-1:-1:1
       if cotracker < 2 
            if fx(joe) == " " || fx(joe) == ")" || fx(joe) == "(" || fx(joe) == "^"
                continue
            elseif fx(joe) == "-"
                if covalue == true
                    covalues(cotracker) = covalues(cotracker)*-1;
                else
                    expvalues(cotracker) = expvalues(cotracker) *-1;
                end
            elseif fx(joe) == "t"
                covalue= false; %when I see "t" I know its an exp value
                cotracker = cotracker+1;
                nbase = 0;
                covalues(end+1)=0;
                expvalues(end+1)=0;
                if covalues(cotracker-1)==0
                    covalues(cotracker-1)=1;
                end
                if expvalues(cotracker-1) ==0
                    expvalues(cotracker-1) =1;
                end
                
            elseif fx(joe) == "e" %when its "e" I know its a co value
                covalue = true;
                nbase=0;
            else
                if covalue == true %increase the value at the current index of covalues
                    covalues(cotracker) = covalues(cotracker)+ str2double(fx(joe))*10^nbase;
                    nbase = nbase+1;
                else %increase the value at the current index of expvalues
                    expvalues(cotracker) = expvalues(cotracker)+str2double(fx(joe))*10^nbase;
                end
            end
       end
    end
    if covalues(1)>1
        covalues(1) = covalues(1) -1;
    end
    if expvalues(1) > 1
        expvalues(1) = expvalues(1)-1;
    end
    %All values of coefficients and exponents derived by algebraic
    %manipulation of the variation of parameters
    psco = (((covalues(1)/(rttwo-rtone))/(expvalues(1)-rtone))*-1 + (covalues(1)/(rttwo-rtone))/(expvalues(1)-rttwo))/coefficients(3);%coefficient of the particular solution real roots
    ipsco = covalues(1)/(((expvalues(1)-realpart)^2+complexpart^2)*coefficients(3)); %coefficient of the particular solution when the roots are complex
    foco = covalues(1) / (coefficients(2)*(expvalues(1)+(coefficients(1)/coefficients(2)))); %first order coefficient of particular solution
    foexp = -1*coefficients(1)/coefficients(2); %first order exponent of particular solution
    comgen = '';
        if highestcount == 2 %complete general solutions
            if cotracker == 1 
                if negative == false
                    comgen = sprintf('The complete general solution of %s(t) is C1e^(%gt) + C2e^(%gt) + (%g)e^(%gt)\n',chosenvarname,rtone,rttwo,psco,expvalues(1)); %2 distinct
                    equationdata=equationdatabuilder('distinct',rtone,rttwo,psco,expvalues(1));
                    if rtone == rttwo
                        comgen = sprintf('The complete general solution of %s(t) is C1e^(%gt) + C2te^(%gt) + (%g)e^(%gt)\n',chosenvarname,rtone,rttwo,psco,expvalues(1)); % repeated
                        equationdata=equationdatabuilder('repeated',rtone,rttwo,psco,expvalues(1));
                    end
                elseif negative == true
                    comgen = sprintf('The complete general solution of %s(t) is e^(%gt)(C1cos(%gt)+C2sin(%gt) + (%g)e^(%gt)\n', chosenvarname,realpart, complexpart, complexpart, ipsco, expvalues(1)); %complex
                    equationdata=equationdatabuilder('complex',realpart,complexpart,ipsco,expvalues(1));
                    %(type, rootone, roottwo, copart, rootpart)
                end
            end
        elseif highestcount == 1 
            if cotracker == 1
                comgen = sprintf('The complete general solution for %s(t) is (%g)e^(%gt)+Ce^(%gt)\n',chosenvarname,foco,expvalues(1),foexp); %1st order
            end
        end
    if keywordscontained(3) == true  
        disp(comgen)
    end
    if cotracker == 1 
        if keywordscontained(4) == true && highestcount == 2 %particular
            if negative == false
                fprintf('The particular solution is (%g)e^(%gt)\n',psco,expvalues(1));% 2 distinct or repeated
            else
                fprintf('The particular solution is (%g)e^(%gt)\n',ipsco,expvalues(1)); % complex
            end
        elseif keywordscontained(4) == true && highestcount == 1
            fprintf('The particular solution is (%g)e^(%gt)\n',foco, expvalues(1)); %1st order
        end
    end

elseif keywordscontained(4) == true || keywordscontained(3) == true
    fprintf('Dude its homogenous');
end
%----------------------------Initial Values--------------------------------
if keywordscontained(5) == true
    init = input('What is x(0)?: ');
    initderiv = input('What is dx/dt(0)?: ');
    [neweq] = solvesystem(equationdata,init,initderiv);
    disp(neweq)
end