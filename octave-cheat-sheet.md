# Basic Operations

## Elementary Math Operations

```
5+6       % adding
3-2       % substrating
5*8       % multiplication
1/2       % division
2^6       % power
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
log(v)                % element-wise logarithm
exp(v)                % element-wise exponentiotion
abs(v)                % element-wise absolute value
-v                    % same as -1 * v
v + ones(length(v),1) % increment each element of vector v by 1
```
