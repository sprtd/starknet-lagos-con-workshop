use starknet::{ get_caller_address, ContractAddress };
use snforge_std::{ 
    declare,
    ContractClassTrait, 
    start_prank, 
    stop_prank, 
    CheatTarget
 };
 use hands_on::{ counter_v4::{ ICounterV4Dispatcher, ICounterV4DispatcherTrait, ICounterV4SafeDispatcher, ICounterV4SafeDispatcherTrait}, errors:: Errors } ;


 // deploy util function 
 fn deploy_contract_with_constructor() -> ContractAddress {
    // declare
    let contract_class = declare("CounterV4").unwrap();

    // construct args
    let constructor_calldata = array![Accounts::owner().into()];

    // deploy
    let (contract_address, _) = contract_class.deploy(@constructor_calldata).unwrap();
    contract_address 
 }


#[test]
fn test_set_new_owner() {
    let contract_address = deploy_contract_with_constructor();

    let dispatcher = ICounterV4Dispatcher{ contract_address };
    let owner = Accounts::owner();

    let count_1 = dispatcher.get_count();
    assert_eq!(count_1, 0);

    let contract_owner_1 = dispatcher.get_owner();
    assert_eq!(owner, contract_owner_1);

    let user_1 = Accounts::user_1();

    start_prank(CheatTarget::One(contract_address), owner );

    dispatcher.set_owner(user_1);

    let contract_owner_2 = dispatcher.get_owner();
    // dispatcher.get_owner()
    assert_eq!(user_1, contract_owner_2);
}


#[test]
#[feature("safe_dispatcher")]
fn test_cannot_set_addr_zero_as_new_owner() {
    let owner = Accounts::owner();
    let zero_account = Accounts::zero();

    let contract_address = deploy_contract_with_constructor();
    let safe_dispatcher = ICounterV4SafeDispatcher{ contract_address };

    let contract_owner_1 = safe_dispatcher.get_owner();
    assert_eq!(owner, contract_owner_1.unwrap());

    let count_1 = safe_dispatcher.get_count();
    assert_eq!(count_1.unwrap(), 0);

    start_prank(CheatTarget::One(contract_address), owner);
    match safe_dispatcher.set_owner(zero_account) {
        Result::Ok(_) => core::panic_with_felt252('should have panicked'), 
        Result::Err(panic_data) => {
            println!("panic data____{:?}__", panic_data);
            println!("panic data____{:?}__", panic_data.at(0));
            assert(*panic_data.at(0) == Errors::ZERO_ADDRESS_OWNER, *panic_data.at(0))
        }
    }
}


#[test]
#[feature("safe_dispatcher")]
fn test_non_owner_attempt_to_set_new_owner() {
    let owner = Accounts::owner();
    let user_1 = Accounts::user_1();
    let user_2 = Accounts::user_2();
    let zero_account = Accounts::zero();

    let contract_address = deploy_contract_with_constructor();
    let safe_dispatcher = ICounterV4SafeDispatcher{ contract_address };

    let contract_owner_1 = safe_dispatcher.get_owner();
    assert_eq!(owner, contract_owner_1.unwrap());

    let count_1 = safe_dispatcher.get_count();
    assert_eq!(count_1.unwrap(), 0);

    start_prank(CheatTarget::One(contract_address), user_1);
    match safe_dispatcher.set_owner(user_1) {
        Result::Ok(_) => core::panic_with_felt252('should have panicked'), 
        Result::Err(panic_data) => {
            println!("panic data____{:?}__", panic_data);
            println!("panic data____{:?}__", panic_data.at(0));
            assert(*panic_data.at(0) == Errors::CALLER_NOT_OWNER, *panic_data.at(0))
        }
    }
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

    pub fn zero() -> ContractAddress {
        0x0000000000000000000000000000000000000000.try_into().unwrap()
    }
}