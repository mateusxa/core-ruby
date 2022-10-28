<?php

namespace Test\RestGet;
use Exception;
use Test\Utils\User;
use StarkCore\Utils\Rest;
use StarkCore\Utils\Checks;
use StarkCore\Utils\Resource;
use StarkCore\Utils\StarkHost;


class Transaction extends Resource
{
    function __construct(array $params)
    {
        parent::__construct($params);
        $this->amount = Checks::checkParam($params, "amount");
    }

    public static function resource()
    {
        $transaction = function ($array) {
            return new Transaction($array);
        };
        return [
            "name" => "Transaction",
            "maker" => $transaction,
        ];
    }
}


class TestRestGet
{    
    public function testSuccess()
    {
        list($transactions, $_cursor) = Rest::getPage(
            "0.0.0",
            StarkHost::bank,
            "v2",
            User::exampleProject(),
            Transaction::resource(),
            "pt-BR",
            15,
            ["before" => "2022-02-01", "limit" => 1]
        );

        $transaction = $transactions[0];
        if (!is_int($transaction-> amount)){
            throw new Exception("failed");
        }
    }
}

echo "\n\nRest Get:";
$tests = new TestRestGet();

echo "\n\t- success";
$tests->testSuccess();
echo " - OK";
