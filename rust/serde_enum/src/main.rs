use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
struct StructA {
    name: String,
    age: i32,
}

#[derive(Debug, Serialize, Deserialize)]
struct StructB {
    title: String,
    description: String,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(untagged)]  // This is crucial for deserializing enums from different possible JSON shapes.
enum MyEnum {
    A(StructA),
    B(StructB),
}

fn main() {
    let json_a = r#"{
        "name": "John",
        "age": 30
    }"#;

    let json_b = r#"{
        "title": "My Title",
        "description": "This is a description"
    }"#;

    let result_a: Result<MyEnum, _> = serde_json::from_str(json_a);
    let result_b: Result<MyEnum, _> = serde_json::from_str(json_b);

    match result_a {
        Ok(MyEnum::A(data)) => println!("Parsed as StructA: {:?}", data),
        Ok(MyEnum::B(data)) => println!("Parsed as StructB: {:?}", data),
        Err(e) => println!("Failed to parse: {}", e),
    }

    match result_b {
        Ok(MyEnum::A(data)) => println!("Parsed as StructA: {:?}", data),
        Ok(MyEnum::B(data)) => println!("Parsed as StructB: {:?}", data),
        Err(e) => println!("Failed to parse: {}", e),
    }
}
