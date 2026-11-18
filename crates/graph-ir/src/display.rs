//! Expressions as text, for people: the notation `inframe graph inspect` prints and
//! `inframe serve` shows. It is not a wire format and nothing parses it back.

use serde_json::Value;

use crate::{Address, Expr, TemplatePart};

/// An expression in the notation `graph inspect` prints: symbolic, and never resolving a secret.
#[must_use]
pub fn format_expr(expression: &Expr) -> String {
    match expression {
        Expr::Literal { value } => format_json(value),
        Expr::ResourceAttr { address, path } | Expr::DataSourceAttr { address, path } => {
            format_reference(address, path)
        }
        Expr::Array { items } => format!(
            "[{}]",
            items.iter().map(format_expr).collect::<Vec<_>>().join(", ")
        ),
        Expr::Object { fields } => format!(
            "{{{}}}",
            fields
                .iter()
                .map(|(name, value)| format!("{name}: {}", format_expr(value)))
                .collect::<Vec<_>>()
                .join(", ")
        ),
        Expr::Index { collection, key } => {
            format!("{}[{}]", format_expr(collection), format_expr(key))
        }
        Expr::Attribute { of, name } => format!("{}.{name}", format_expr(of)),
        Expr::Splat { of } => format!("{}[*]", format_expr(of)),
        Expr::Conditional {
            condition,
            when_true,
            when_false,
        } => format!(
            "if {} then {} else {}",
            format_expr(condition),
            format_expr(when_true),
            format_expr(when_false)
        ),
        Expr::Function { name, args } => format!(
            "{name}({})",
            args.iter().map(format_expr).collect::<Vec<_>>().join(", ")
        ),
        Expr::Template { parts } => format!(
            "template({})",
            parts
                .iter()
                .map(|part| match part {
                    TemplatePart::Literal { value } => format_json(&Value::String(value.clone())),
                    TemplatePart::Interpolation { expression } => {
                        format!("${{{}}}", format_expr(expression))
                    }
                })
                .collect::<Vec<_>>()
                .join(", ")
        ),
        Expr::SecretEnv { name } => {
            format!("secretEnv({})", format_json(&Value::String(name.clone())))
        }
        Expr::UnsafeRaw { expression } => format!(
            "unsafeRaw({})",
            format_json(&Value::String(expression.clone()))
        ),
    }
}

/// A reference to an attribute of a node, `address.path`.
#[must_use]
pub fn format_reference(address: &Address, path: &[String]) -> String {
    if path.is_empty() {
        address.to_string()
    } else {
        format!("{address}.{}", path.join("."))
    }
}

/// A literal JSON value, with object keys in order.
#[must_use]
pub fn format_json(value: &Value) -> String {
    match value {
        Value::Null => "null".to_owned(),
        Value::Bool(value) => value.to_string(),
        Value::Number(value) => value.to_string(),
        Value::String(value) => serde_json::to_string(value).expect("strings always serialize"),
        Value::Array(items) => format!(
            "[{}]",
            items.iter().map(format_json).collect::<Vec<_>>().join(", ")
        ),
        Value::Object(fields) => {
            let mut fields: Vec<_> = fields.iter().collect();
            fields.sort_by_key(|(name, _)| *name);
            format!(
                "{{{}}}",
                fields
                    .into_iter()
                    .map(|(name, value)| format!(
                        "{}: {}",
                        serde_json::to_string(name).expect("object keys always serialize"),
                        format_json(value)
                    ))
                    .collect::<Vec<_>>()
                    .join(", ")
            )
        }
    }
}
