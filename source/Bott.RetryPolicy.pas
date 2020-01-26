unit Bott.RetryPolicy;

interface

{
The 3-Clause BSD License aka "New BSD License" or "Modified BSD License"

Copyright (c) 2020 Bernd Ott aka codingBOTT
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  
}

uses
  System.SysUtils;

type
  /// <summary>
  /// Will be called if a exception is throw
  /// </summary>
  /// <returns>
  /// true when the exception should be supressed.
  /// false when it should raised.
  /// </returns>
  TOnException = reference to function(e: Exception): boolean;

  TOnBeforeRetry = reference to function(retry, maxRetries: cardinal;
    lastException: Exception): boolean;

  IRetryPolicy = interface
    // Setup methodes
    function onException(proc: TOnException): IRetryPolicy;
    function onRetry(proc: TOnBeforeRetry): IRetryPolicy;

    function retry(): IRetryPolicy; overload;
    function retry(count: cardinal): IRetryPolicy; overload;

    function WaitAndRetry(delayInMilliseconds: cardinal): IRetryPolicy;
      overload;
    function WaitAndRetry(delayInMilliseconds, count: cardinal)
      : IRetryPolicy; overload;

    // Finall call this to run your code
    function Execute(proc: TProc): boolean;
  end;

  TRetryPolicyFactory = class
  public
    class function GetInstance: IRetryPolicy;
  end;

implementation

uses
  System.Generics.Collections;

type
  TRetryPolicy = class(TInterfacedObject, IRetryPolicy)
  strict private
    fWaitsBetweenRetries: TList<integer>;
    fonException: TOnException;
    fonBeforeRetry: TOnBeforeRetry;

    function exceptionHandling(lastException: Exception): boolean;
    function retryHandling(retryCount: integer;
      lastException: Exception): boolean;
  public
    constructor Create();
    destructor Destroy(); override;

    // Setup
    function onException(proc: TOnException): IRetryPolicy;

    function onRetry(proc: TOnBeforeRetry): IRetryPolicy;

    function retry(): IRetryPolicy; overload;
    function retry(count: cardinal): IRetryPolicy; overload;

    function WaitAndRetry(delayInMilliseconds: cardinal): IRetryPolicy;
      overload;
    function WaitAndRetry(delayInMilliseconds, count: cardinal)
      : IRetryPolicy; overload;

    // Use
    function Execute(proc: TProc): boolean;
  end;

{ TRetryPolicy }

constructor TRetryPolicy.Create;
begin
  fonException := nil;
  fonBeforeRetry := nil;
  fWaitsBetweenRetries := TList<integer>.Create();
end;

destructor TRetryPolicy.Destroy;
begin
  fWaitsBetweenRetries.Free;
  inherited;
end;

function TRetryPolicy.exceptionHandling(lastException: Exception): boolean;
begin
  result := assigned(fonException) and not fonException(lastException);
end;

function TRetryPolicy.retryHandling(retryCount: integer;
  lastException: Exception): boolean;
var
  policy: boolean;
begin
  // when there are retries respect the delay between
  // if not then skip this and break instant.

  policy:=((fWaitsBetweenRetries.count > 0) and (retryCount < fWaitsBetweenRetries.count));

  result :=
    // check if there are polices
      policy
    or
    // there is a retrycallback
      (assigned(fonBeforeRetry) and fonBeforeRetry(retryCount + 1, fWaitsBetweenRetries.count, lastException));

  if result and policy then
    Sleep(fWaitsBetweenRetries.Items[retryCount]);
end;

/// <summary>
/// This function executes the business logic.
/// when a exception is raised, then it will be handled.
/// </summary>
/// <returns>
/// true if call was success
/// false if call was not a success
/// </returns>
function TRetryPolicy.Execute(proc: TProc): boolean;
var
  retryCount: cardinal;
begin
  retryCount := 0;

  while true do
  begin
    try
      proc();
      result := true;
      exit;
    except
      on e: Exception do
      begin
        if exceptionHandling(e) then
          raise;

        if retryHandling(retryCount, e) then
        begin
          retryCount := retryCount + 1;
          Continue;
        end;

        break;
      end
    end;
  end;
  result := false;
end;

function TRetryPolicy.onException(proc: TOnException): IRetryPolicy;
begin
  fonException := proc;
  result := self;
end;

/// <summary>
/// assignes the callback which is executed before each retry.
/// </summary>
/// <returns>
/// true when a new retry should done.
/// false when the execute should not called and the retry loop have to canceled.
/// </returns>
function TRetryPolicy.onRetry(proc: TOnBeforeRetry): IRetryPolicy;
begin
  fonBeforeRetry := proc;
  result := self;
end;

function TRetryPolicy.retry(count: cardinal): IRetryPolicy;
begin
  result := WaitAndRetry(0, count);
end;

function TRetryPolicy.WaitAndRetry(delayInMilliseconds: cardinal): IRetryPolicy;
begin
  fWaitsBetweenRetries.Add(delayInMilliseconds);
  result := self;
end;

function TRetryPolicy.WaitAndRetry(delayInMilliseconds, count: cardinal)
  : IRetryPolicy;
var
  i: cardinal;
begin
  if count < 1 then
    raise EArgumentOutOfRangeException.Create
      ('Count parameter has to be greater than 0 (milliseconds).');

  for i := 0 to count - 1 do
    WaitAndRetry(delayInMilliseconds);

  result := self;
end;

function TRetryPolicy.retry: IRetryPolicy;
begin
  result := WaitAndRetry(0);
end;

{ TRetryPolicyFactory }

class function TRetryPolicyFactory.GetInstance: IRetryPolicy;
begin
  result := TRetryPolicy.Create();
end;

end.
