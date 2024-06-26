use starknet::{get_caller_address, ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventFetcher, Event,
};


use hands_on::counter_v3::{
    ICounterV3Dispatcher, ICounterV3DispatcherTrait, ICounterV3SafeDispatcher,
    ICounterV3SafeDispatcherTrait
};

// utility deploy function 
fn deploy_contract_with_constructor() -> ContractAddress {
    // declare 
    let contract_class = declare("CounterV3").unwrap();

    // pass in constructor args
    let constructor_calldata = array![Accounts::owner().into()];

    // deploy contract to generate contract address
    let (contract_address, _) = contract_class.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_emitted_event() {
    let contract_address = deploy_contract_with_constructor();
    let dispatcher = ICounterV3Dispatcher { contract_address };
    let count_1 = dispatcher.get_count();
    assert_eq!(count_1, 0);

    // initiate increase_count with owner account
    start_prank(CheatTarget::One(contract_address), Accounts::owner());
    let mut spy = spy_events(SpyOn::One(contract_address));
    assert(spy._id == 0, 'Id should be 0');

    dispatcher.increase_count(10);
    spy.fetch_events();

    assert(spy.events.len() == 1, 'there should be one event');

    let (from, event) = spy.events.at(0);
    assert_eq!(from, @contract_address);
    println!("stored count event___{}", event.keys.at(0));
    assert_eq!(event.keys.at(0), @selector!("StoredCount"));

    let count_2 = dispatcher.get_count();
    assert_eq!(count_2, 10);
    println!("events len___{}", spy.events.len());
}


// test accounts to simulate different users 
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

    pub fn zero() -> ContractAddress {
        0x0000000000000000000000000000000000000000.try_into().unwrap()
    }
}
