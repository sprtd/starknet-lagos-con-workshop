use starknet::{ContractAddress};
use snforge_std::{declare, ContractClassTrait};
use hands_on::addition::add_num;


use hands_on::{
    counter::{
        ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
        ICounterSafeDispatcherTrait
    },
    errors::Errors
};

pub fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
#[ignore]
#[feature("safe_dispatcher")]
fn test_cannot_increase_count_with_zero() {
    let contract_address = deploy_contract("CounterContract");
    let safe_dispatcher = ICounterSafeDispatcher { contract_address };
    let current_count = safe_dispatcher.get_count().unwrap();
    assert(current_count == 0, Errors::INVALID_COUNT_VALUE);

    match safe_dispatcher.increase_count(current_count) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == Errors::ZERO_AMOUNT, *panic_data.at(0));
        }
    }
}

#[test]
#[ignore]
#[should_panic(expected: 'amount cannot be zero')]
fn test_cannot_increase_count_panic_with_felt() {
    let contract_address = deploy_contract("CounterContract");
    println!("contract address____{:?}__", contract_address);
    let dispatcher = ICounterDispatcher { contract_address };
    let current_count = dispatcher.get_count();
    assert(current_count == 0, Errors::INVALID_COUNT_VALUE);
    dispatcher.increase_count(current_count);
}

#[test]
#[feature("safe_dispatcher")]
fn test_increase_count() {
    let contract_address = deploy_contract("CounterContract");
    let counter = ICounterSafeDispatcher { contract_address };
    let count_1 = counter.get_count().unwrap();
    assert(count_1 == 0, Errors::INVALID_COUNT_VALUE);
    assert_eq!(count_1, 0);

    let increase_count_result = counter.increase_count(10);
    assert!(increase_count_result.is_ok());
    let final_count: u32 = add_num(0, 10);
    assert_eq!(final_count, 10);
}

