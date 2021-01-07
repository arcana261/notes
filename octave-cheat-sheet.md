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
