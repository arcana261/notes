# Basic Operations

## Elementary Math Operations

```
5+6       % adding
3-2       % substrating
5*8       % multiplication
1/2       % division
2^6       % power
```

```
quit      % exit octave
exit      % exit octave
```

## Logical Operations

```
1 == 2    % equals, evals to 0 which means false
1 ~= 2    % not equals, evals to 1 which means true
1 && 0    % logical and
1 || 0    % logical or
xor(1,0)  % logical xor
```

## Chaning Prompt

```
PS1('>> ')
```

## Variables

```
a = 3                                  % assign 3 to variable a
a = 3;                                 % semicolon prevents printing result
b = 'hi';                              % string assignment
c = (3>=1);                            % c = 1
a = pi;                                % assign pi number to variable a
disp(a);                               % for more complex printing or debug in functions
disp(sprintf('2 decimals: %0.2f', pi)) % advanced c-like string formatting
disp(sprintf('6 decimals: %0.6f', pi)) % advanced c-like string formatting
format long                            % print long version of numbers
format short                           % print short version of numbers
a=1, b=2, c=3;                         % comma-chaining multiple commands
```

## Matrices

```
A = [1 2; 3 4; 5 6];      % declare a matrix
% A =
%
%   1 2
%   3 4
%   5 6

A = [1 2;
3 4;
5 6]                     % declare matrix multi-line


v = [1 2 3]       % a row vector
v = [1; 2; 3]     % a column vector

v = 1:0.1:2
% [1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

v = 1:6
% [1 2 3 4 5 6]

ones(2,3)
% ans =
%       1 1 1
%       1 1 1

C = 2*ones(2,3)
% C =
%    2 2 2
%    2 2 2

w = ones(1,3)
% w =
%     1 1 1

w = zeros(1,3)
% w =
%     0 0 0

eye(4)
% ans =
%       1 0 0 0
%       0 1 0 0
%       0 0 1 0
%       0 0 0 1

eye(6)
% ans =
%       1 0 0 0 0 0
%       0 1 0 0 0 0
%       0 0 1 0 0 0
%       0 0 0 1 0 0
%       0 0 0 0 1 0
%       0 0 0 0 0 1

eye(3)
% ans =
%       1 0 0
%       0 1 0
%       0 0 1

w = rand(1,3)                            % generate 1x3 random number [0,1) matrix
rand(3,3)                                % generate 3x3 random number [0,1) matrix
w = randn(1,3)                           % generate 1x3 gaussian distribution matrix
```

## Plot histogram

```
hist(-6 + sqrt(10)*(randn(1,10000)))     % plot histogram of vector
hist(-6 + sqrt(10)*(randn(1,10000)),50)  % plot histogram of vector with 50 buckets
```

## Help command
```
help eye    % get help about identity function
help rand   % get help about rand
help help   % get help about help
```

# Moving Data Around

## Getting information about matrix

```
size(A)
% ans =
%       3 2
% this shows that matrix is a 3x2 matrix (3 rows 2 columns)

size(size(A))
% ans =
%       1 2

size(A, 1)          % get number of rows
size(A, 2)          % get number of columns
length([1 2 3 4])   % gives size of longest dimention, in this case 4
```

## Loading and Saving data

```
pwd                      % get current working directory
cd '/path'               % change directory to path
ls                       % list files in pwd
load file.dat            % load file.dat into variable file
load('file.dat')         % load file.dat into variable file
who                      % list variables
whos                     % list variables with their sizes
clear file               % delete variable file
save hello.mat v         % save variable v into file hello.mat in a compressed format
save hello.txt v  -ascii % save variable v into file hello.txt in a human readable format
```

## Manipulate data
```
A(3,2)                % return cell at row 3, column 2
v(1:10)               % returns first 10 rows of data
A(2,:)                % fetch everything in the second row
A(:,2)                % everything in the second column
A([1 3],:)            % first and third row only
A(:,2) = [10; 11; 12] % assign 10,11,12 to second column
A = [A, [1; 2; 3;]];  % append a new column vector to the right
A(:)                  % put all elements of A inside a column vector
C = [A B]             % concatenate A and B together from right of A
C = [A, B]            % concatenate A and B together from right of A
C = [A; B]            % concatenate A and B together from bottom of A
```

# Computing on Data

## Basic computation

```
A * C                 % multiply matrices A, C
A .* B                % multiply matrices A, B element-wise instead of normal matrix multiplication
A .^ 2                % element-wise squaring of A
1 ./ v                % element-wise inverse
a < 3                 % element-wise comparison
find(a < 3)           % returns a vector of indices, where a was < 3
log(v)                % element-wise logarithm
exp(v)                % element-wise exponentiotion
abs(v)                % element-wise absolute value
-v                    % same as -1 * v
v + ones(length(v),1) % increment each element of vector v by 1
v + 1                 % increment each element of vector v by 1, much simpler version!
A'                    % transpose of matrix A
```

## Useful functions

```
max(a)                % maximum of vector a
[val, ind] = max(a)   % maximum of vector a and it's column
max(A)                % column-wise maximum of A
magic(4)              % return a 4x4 "magic" matrix
[r, c] = find(A >= 7) % return r,c as column vectors holding indices of locations A >=7
sum(a)                % adds all elements of vector a
sum(A,1)              % take column-wise sum of matrix A
sum(A,2)              % take row-wise sum of matrix A
prod(a)               % product of all elements of vector a
floor(a)              % element-wise floor
ceil(a)               % element-wise ceiling
max(A, B)             % take element-wise maximum of two matrices
max(A,[],1)           % take column-wise maximum of A
max(A)                % take column-wise maximum of A
max(A, [], 2)         % take row-wise maximum of A
max(max(A))           % maximum element in matrix A
sum(sum(A .* eye(9))) % sum main diagonal
flipud(A)             % flip up-down matrix
sum(sum(A .* flipud(eye(9)))) % sum secondary diagonal
pinv(A)               % return inverse of matrix A
std(a)                % standard deviation of vector a
```

# Plotting Data

```
t =[0:0.1:1];
y1=sin(2*pi*4*t);
y1=cos(2*pi*4*t);         % suppose we have these variables

plot(t, y1);              % plot sin(x)
plot(t, y2, 'r');         % plot cos(x) in red color

plot(t, y1);
hold on;                  % plot y1, y2 on each other
plot(t, y2, 'r');
xlabel('time');           % label horizontal axis
ylabel('value');          % label vertical axis
legend('sin', 'cos');     % add legend to plot
title('my plot');         % gives a title to entire plot
print -dpng 'myPlot.png'  % save plot in png format
close                     % close open plot

figure(1);
plot(t, y1);
figure(2);
plot(t, y2);              % don't override previous plot, simply open a new window instead

subplot(2, 1, 1);         % divide plot into 2x1 grid and start accessing first element
plot(t, y1);              % plot in first element of grid
subplot(2, 1, 2);         % access second element
plot(t, y2);              % plot in second element of grid

axis(0.5 1 -1 1);         % change axis: x-range and y-range of plot

clf                       % clears the figure

A=magic(5);
imagesc(A);                           % show a colorful heatmap of A
imagesc(A), colorbar, colorbar gray;  % show a grayscale heatmap of A

plot(t, y1, 'rx');                    % plot data in scattered mode using * sign
plot(t, y1, 'rx', 'MarkerSize', 10);  % plot data in scattered mode and with custom marker size
plot(t, y1, 'k+');                    % plot data in scattered using + sign
plot(t, y1, 'ko');                    % plot data in scattered using o sign
plot(t, y1, 'LineWidth', 2);          % adjust border size
plot(t, y1, 'MarkerFaceColor', 'y');  % set color of sign to yellow
```
# Control Statements

## for loop

```
v = zeros(10,1)

for i = 1:10,
  v(i) = 2^i,
end;
```

```
indices = 1:10;

for i = indices,
  disp(i),
end;
```

## while loop

```
i = 1;
while i <= 5,
  v(i) = 100,
  i = i+1,
end;
```

```
while true,
  v(i) = 999,
  i = i+1;
  if i == 6,
    break,
  end,
end;
```

## if statement

```
if v(1) == 1,
  disp('The value is 1');
elseif v(1) == 2,
  disp('The value is 2');
else,
  disp('The value is neither 1 or 2');
end;
```

# Functions

## Declaring

To define function `squareThisNumber` we have to put definition inside file `squareThisNumber.m` and it should be accessible via:

1. either `pwd` which can be navigated by `cd`
2. search directory which can be appended by `addpath('path')`

```
function y = squareThisNumber(x)

y = x ^ 2;
```

## Functions with Multiple Outputs

```
function [y1,y2] = squareAndCubeThisNumber(x)

y1 = x^2;
y2 = x^3;
```

This declaration can be invoked using:

```
[a, b] = squareAndCubeThisNumber(5);
```

## Linear Regression Cost Function

```
function J = function(X, y, theta)

% X is the "design matrix" containing our training examples
% y is the class labels

m = size(X, 1)                      % number of training examples
predictions = X * theta             % predictions of hypothesis on all m examples
sqrErrors = (predictions - y).^2    % squared errors

J = 1/(2*m) * sum(sqrErrors)
```

# Optimization

## When number of features is low:

Use `fminunc` function.

```
options = optimset('GradObj', 'on', 'MaxIter', 100);
initialTheta = zeros(size(data,2),1);
[optTheta, functionVal, exitFlag] = fminunc(@(t)(costFunction(t, X, y)), initialTheta, options);

```

## When number of features is high:

Use `fmincg` function.

```
options = optimset('GradObj', 'on', 'MaxIter', 100);
initialTheta = zeros(size(data,2),1);
[optTheta, functionVal, exitFlag] = fmincg(@(t)(costFunction(t, X, y)), initialTheta, options);

```

# Rolling/Unrolling

```
thetaVec = [ Theta1(:); Theta2(:); Theta3(:) ]
Theta1 = reshape(thetaVec(1:110), 10, 11)
Theta2 = reshape(thetaVec(111:220), 10, 11)
Theta3 = reshape(thetaVec(221:231), 1, 11)
```
