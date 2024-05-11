use starknet::{ContractAddress, get_caller_address};
use snforge_std::{
    declare, 
    ContractClassTrait, 
    start_prank, 
    stop_prank, 
    CheatTarget, 
    CheatSpan, prank
};
// use snforge_std::CheatnetState::prank;

use hands_on::{
    counter_v2::{
        ICounterV2Dispatcher, ICounterV2DispatcherTrait, ICounterV2SafeDispatcher,
        ICounterV2SafeDispatcherTrait
    },
    errors::Errors, addition::add_num
};

use Accounts::{owner, user_1, user_2};

fn deploy_contract_with_constructor() -> ContractAddress {
    let counter_v2_contract_class = declare("CounterV2").unwrap();
    let mut calldata = array![Accounts::owner().into()];
    let (contract_address, _) = counter_v2_contract_class.deploy(@calldata).unwrap();
    contract_address
}


pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn owner() -> ContractAddress {
        'owner'.try_into().unwrap()
    }

    pub fn user_1() -> ContractAddress {
        '1'.try_into().unwrap()
    }

    pub fn user_2() -> ContractAddress {
        '2'.try_into().unwrap()
    }
}

#[test]
#[ignore]
fn test_counter_v2_deployment() {
    let counter_v2_addr = deploy_contract_with_constructor();
    let counter_v2 = ICounterV2Dispatcher { contract_address: counter_v2_addr };
    let owner = counter_v2.get_owner();
    println!("owner____ {:?}", owner);
    assert(owner == Accounts::owner(), Errors::NOT_OWNER);
    assert_ne!(owner, Accounts::user_1());
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_increase_count_with_other_addr() {
    let contract_address = deploy_contract_with_constructor();
    let safe_dispatcher = ICounterV2SafeDispatcher { contract_address };

    let user_1: ContractAddress = Accounts::user_1();

    // Change the caller address to user_1 before calling increase_count
    start_prank(CheatTarget::One(contract_address), user_1);
    match safe_dispatcher.increase_count(100) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            println!("error from calling using another user___{:?}", panic_data);
            assert(*panic_data.at(0) == Errors::NOT_OWNER, *panic_data.at(0));
        }
    }
}


#[test]
#[feature("safe_dispatcher")]
fn test_increase_count_with_zero_amount() {
    let contract_address = deploy_contract_with_constructor();
    let safe_dispatcher = ICounterV2SafeDispatcher { contract_address };
    let owner = Accounts::owner();
    let count_1 = safe_dispatcher.get_count().unwrap();
    assert_eq!(count_1, 0);

    start_prank(CheatTarget::One(contract_address), owner);
    match safe_dispatcher.increase_count(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(err) => { assert(*err.at(0) == Errors::ZERO_AMOUNT, *err.at(0)); }
    }
}

// positive 
#[test]
fn test_increase_count() {
    let contract_address = deploy_contract_with_constructor();
    let dispatcher = ICounterV2Dispatcher { contract_address };
    let count_1 = dispatcher.get_count();
    assert_eq!(count_1, 0);

    let owner_from_counter: ContractAddress = dispatcher.get_owner();
    println!("owner from count____{:?}", owner_from_counter);
    let owner: ContractAddress = Accounts::owner();

    // Prank the contract_address for a span of 2 target calls (here, calls to contract_address)
    // prank(CheatTarget::One(contract_address), owner, CheatSpan::TargetCalls(2));
    start_prank(CheatTarget::One(contract_address), owner);

    // owner increase count txn
    dispatcher.increase_count(10);

    // calculate latest count
    let count_sum_result: u32 = add_num(0, 10);
    assert_eq!(count_sum_result, 10);

    let count_2: u32 = dispatcher.get_count();
    assert_eq!(count_2, count_sum_result);

    // owner increase count txn
    dispatcher.increase_count(5);
    let count_3: u32 = dispatcher.get_count();
    // core::panic_with_felt252('should have panicked')

    let count_sum_result_2: u32 = add_num(count_sum_result, 5);
    assert_eq!(count_sum_result_2, 15);

    assert_eq!(count_3, count_sum_result_2);
}

