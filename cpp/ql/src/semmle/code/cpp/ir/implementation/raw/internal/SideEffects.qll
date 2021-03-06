/**
 * Predicates to compute the modeled side effects of calls during IR construction.
 *
 * These are used in `TranslatedElement.qll` to generate the `TTranslatedSideEffect` instances, and
 * also in `TranslatedCall.qll` to inject the actual side effect instructions.
 */

private import cpp
private import semmle.code.cpp.ir.implementation.Opcode
private import semmle.code.cpp.models.interfaces.SideEffect

/**
 * Holds if the specified call has a side effect that does not come from a `SideEffectFunction`
 * model.
 */
private predicate hasDefaultSideEffect(Call call, ParameterIndex i, boolean buffer, boolean isWrite) {
  not call.getTarget() instanceof SideEffectFunction and
  (
    exists(MemberFunction mfunc |
      // A non-static member function, including a constructor or destructor, may write to `*this`,
      // and may also read from `*this` if it is not a constructor.
      i = -1 and
      mfunc = call.getTarget() and
      not mfunc.isStatic() and
      buffer = false and
      (
        isWrite = false and not mfunc instanceof Constructor
        or
        isWrite = true and not mfunc instanceof ConstMemberFunction
      )
    )
    or
    exists(Expr expr |
      // A pointer-like argument is assumed to read from the pointed-to buffer, and may write to the
      // buffer as well unless the pointer points to a `const` value.
      i >= 0 and
      buffer = true and
      expr = call.getArgument(i).getFullyConverted() and
      exists(Type t | t = expr.getUnspecifiedType() |
        t instanceof ArrayType or
        t instanceof PointerType or
        t instanceof ReferenceType
      ) and
      (
        isWrite = true and
        not call.getTarget().getParameter(i).getType().isDeeplyConstBelow()
        or
        isWrite = false
      )
    )
  )
}

/**
 * Returns a side effect opcode for parameter index `i` of the specified call.
 *
 * This predicate will return at most two results: one read side effect, and one write side effect.
 */
Opcode getASideEffectOpcode(Call call, ParameterIndex i) {
  exists(boolean buffer |
    (
      call.getTarget().(SideEffectFunction).hasSpecificReadSideEffect(i, buffer)
      or
      not call.getTarget() instanceof SideEffectFunction and
      hasDefaultSideEffect(call, i, buffer, false)
    ) and
    if exists(call.getTarget().(SideEffectFunction).getParameterSizeIndex(i))
    then (
      buffer = true and
      result instanceof Opcode::SizedBufferReadSideEffect
    ) else (
      buffer = false and result instanceof Opcode::IndirectReadSideEffect
      or
      buffer = true and result instanceof Opcode::BufferReadSideEffect
    )
  )
  or
  exists(boolean buffer, boolean mustWrite |
    (
      call.getTarget().(SideEffectFunction).hasSpecificWriteSideEffect(i, buffer, mustWrite)
      or
      not call.getTarget() instanceof SideEffectFunction and
      hasDefaultSideEffect(call, i, buffer, true) and
      mustWrite = false
    ) and
    if exists(call.getTarget().(SideEffectFunction).getParameterSizeIndex(i))
    then (
      buffer = true and
      mustWrite = false and
      result instanceof Opcode::SizedBufferMayWriteSideEffect
      or
      buffer = true and
      mustWrite = true and
      result instanceof Opcode::SizedBufferMustWriteSideEffect
    ) else (
      buffer = false and
      mustWrite = false and
      result instanceof Opcode::IndirectMayWriteSideEffect
      or
      buffer = false and
      mustWrite = true and
      result instanceof Opcode::IndirectMustWriteSideEffect
      or
      buffer = true and mustWrite = false and result instanceof Opcode::BufferMayWriteSideEffect
      or
      buffer = true and mustWrite = true and result instanceof Opcode::BufferMustWriteSideEffect
    )
  )
}
