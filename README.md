# Retry Policy
Retry Policy is a small class which helps to build robust code. I allows you as developer to retry or wait and retry function that have failed before. This is done in fluent manner.

# Install / Usage

Just include the "source\Bott.RetryPolicy.pas" into your project. Then call  `TRetryPolicyFactory.GetInstance()` to get an instance of `IRetryPolicy`.

## Retry 3 times (4 tries in total when they fail - initial call and 3 tries)
``` delphi
    TRetryPolicyFactory.GetInstance()
      .Retry(3)
      .Execute(
          procedure()
          begin
            // your code here
          end
      )
```

This code retries three times to execute `your code`. If one of the 4 calls does not raise an exception, the methode `execute` returns `true`. if not `false` will returned.

## Wait 1 second between each retry and try it 3 times
``` delphi
    TRetryPolicyFactory.GetInstance()
      .WaitAndRetry(1000, 2)
      .Execute(
          procedure()
          begin
            // your code here
          end
      )
```

## Chain the trys 
First call to `your code` will be instant. If this fails wait 1 second and retry. If second call also raises an exception, wait 3 second before the last try.
``` delphi
    TRetryPolicyFactory.GetInstance()
      .WaitAndRetry(1000)
      .WaitAndRetry(3000)
      .Execute(
          procedure()
          begin
            // your code here
          end
      )
```
## Use callback to log and/or handle exceptions 

``` delphi
  TRetryPolicyFactory.GetInstance()
    .onException(
      function(e: Exception): boolean
      begin
        // return true when the exception is handled.
        // return false when the exception should re raise.
        result:=true;
      end
    )
    .Execute(
      procedure()
      begin
        // your code here
      end
    );
```    

## Use callback to decide if retries should done

``` delphi
    TRetryPolicyFactory.GetInstance()
      .onRetry( function(retry, maxRetries: cardinal; lastException: Exception): boolean
        begin
          // do in total call `your code` three times.
          result:=retry<3;
        end
      )
      .Execute(
          procedure()
          begin
            // your code here
          end
      )
```

# License

Licensed under the terms of the [New BSD License](http://opensource.org/licenses/BSD-3-Clause)

## The 3-Clause BSD License aka "New BSD License" or "Modified BSD License"

Copyright (c) 2020 Bernd Ott aka codingBOTT
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# discussion board
When you want to discuss this class, join the community here : [delphipraxis.net](https://en.delphipraxis.net/)