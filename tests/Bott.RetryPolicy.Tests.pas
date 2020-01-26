unit Bott.RetryPolicy.Tests;
{

  Delphi DUnit-Testfall
  ----------------------
  Diese Unit enthält ein Skeleton einer Testfallklasse, das vom Experten für Testfälle erzeugt wurde.
  Ändern Sie den erzeugten Code so, dass er die Methoden korrekt einrichtet und aus der 
  getesteten Unit aufruft.

}

interface

uses
  TestFramework,
  System.SysUtils,
  Bott.RetryPolicy;

type
  TRetryPolicyTests = class(TTestCase)
  strict private
    procedure OnExceptionCalledAndExceptionWillRaisedHelper;
  private
  public
  published
    procedure CallReturnsTrueOnSuccess;
    procedure OnExceptionWillCalled;
    procedure OnExceptionCalledAndExceptionWillRaised;
    procedure ProcWillBeCalledFourTimesEvenExceptionIsThrown;
    procedure ProcWillBeCalledThreeTimesWithDelayBetweenCalls;
    procedure OnRetryWillCalledThreeTimes;
    procedure OnRetryWillCancelNextExecute;
  end;

  TRetryPolicyFactoryTests = class(TTestCase)
  published
    procedure InstaceWillBeCreated;
  end;

implementation

uses
  System.DateUtils;

procedure TRetryPolicyTests.OnExceptionWillCalled;
var
  isCalled: boolean;
begin
  isCalled:=false;

  TRetryPolicyFactory.GetInstance()
    .onException(
      function(e: Exception): boolean
      begin
        isCalled:=true;
        // handled
        result:=true;
      end
    )
    .Execute(
      procedure()
      begin
        raise Exception.Create('Something is wrong');
      end
    );

  Check(isCalled);
end;

procedure TRetryPolicyTests.OnRetryWillCalledThreeTimes;
var
  countExecute, countRetry: cardinal;
begin
  countExecute:=0;
  countRetry:=0;

  check(not
    TRetryPolicyFactory.GetInstance()
      .onRetry( function(retry, maxRetries: cardinal; lastException: Exception): boolean
        begin
          countRetry:=countRetry+1;
          result:=retry<3;
        end
      )
      .Execute(
          procedure()
          begin
            countExecute:=countExecute+1;
            raise Exception.Create('Something is wrong');
          end
      )
  );

  // three Retries but third has cancel the retries
  CheckEquals(3, countRetry);

  // so execute is called first, then two retries and third did not return true
  CheckEquals(3, countExecute);
end;

procedure TRetryPolicyTests.OnRetryWillCancelNextExecute;
var
  countExecute, countRetry: cardinal;
begin
  countExecute:=0;
  countRetry:=0;

  check(not
    TRetryPolicyFactory.GetInstance()
      .onRetry( function(retry, maxRetries: cardinal; lastException: Exception): boolean
        begin
          countRetry:=countRetry+1;
          // cancel retries now
          result:=retry<2;
        end
      )
      .Execute(
          procedure()
          begin
            countExecute:=countExecute+1;
            raise Exception.Create('Something is wrong');
          end
      )
  );

  // two Retries but second canceled execute
  CheckEquals(2, countRetry);

  // so only two executes
  CheckEquals(2, countExecute);
end;

/// <summary>
/// proc will be called four times
/// 1. basic call
/// 2. first retry by retry();
/// 3. and 4. by second retry(2);
/// </summary>
procedure TRetryPolicyTests.ProcWillBeCalledFourTimesEvenExceptionIsThrown;
var
  count: integer;
begin
  count:=0;

  check(not
    TRetryPolicyFactory.GetInstance()
      .Retry()
      .Retry(2)
      .Execute(
        procedure()
        begin
          count:=count+1;
          raise Exception.Create('Something is wrong');
        end
      )
  );
  CheckEquals(4, count);
end;

procedure TRetryPolicyTests.ProcWillBeCalledThreeTimesWithDelayBetweenCalls;
var
  startTime, firstCall, secondCall, thirdCall, endTime: TDateTime;
  delay, calls: integer;
begin
  calls:=0;

  startTime:=now;

  check(not
    TRetryPolicyFactory.GetInstance()
      .WaitAndRetry(1000)
      .WaitAndRetry(2000)
      .Execute(
        procedure()
        begin
          case calls of
            0: firstCall:=now;
            1: secondCall:=now;
            2: thirdCall:=now;
          end;
          calls:=calls+1;
          raise Exception.Create('Something is wrong');
        end
      )
  );
  endTime:=now;
  CheckEquals(3, calls);

  // delay to first call should be near 0
  delay:=SecondsBetween(startTime, firstCall);
  check(delay<1);

  // delay between first and second call should be near 1 second
  delay:=SecondsBetween(firstCall, secondCall);
  check(delay>=1);
  check(delay<=2);

  // delay between second and thrid call should be near 2 seconds
  delay:=SecondsBetween(secondCall, thirdCall);
  check(delay>=2);

  // total delay
  delay:=SecondsBetween(startTime, endTime);
  check(delay>=3);
end;

procedure TRetryPolicyTests.OnExceptionCalledAndExceptionWillRaised;
begin
  CheckException(OnExceptionCalledAndExceptionWillRaisedHelper, Exception);
end;

procedure TRetryPolicyTests.OnExceptionCalledAndExceptionWillRaisedHelper();
begin
  TRetryPolicyFactory.GetInstance()
    .onException(
      function(e: Exception): boolean
      begin
        // not handled
        result:=false
      end
    )
    .Execute(
      procedure()
      begin
        raise Exception.Create('Something is wrong');
      end
    );
end;

// procedure can executed
// and a success call returns true
procedure TRetryPolicyTests.CallReturnsTrueOnSuccess;
var
  isCalled: boolean;
begin
  isCalled:=false;

  check(
    TRetryPolicyFactory.GetInstance().execute( procedure()
        begin
          // work which is protected by framework
          isCalled:=true;
        end
      )
  );

  Check(isCalled);
end;

{ TRetryPolicyFactoryTests }

procedure TRetryPolicyFactoryTests.InstaceWillBeCreated;
var
  i: IRetryPolicy;
begin
  i:=TRetryPolicyFactory.GetInstance();
  Check(Assigned(i));
end;

initialization
  // Alle Testfälle beim Testprogramm registrieren
  RegisterTest(TRetryPolicyTests.Suite);
  RegisterTest(TRetryPolicyFactoryTests.Suite);
end.

