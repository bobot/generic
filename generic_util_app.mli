(** Type application and defunctionalisation.

    In OCaml parametric types cannot be partially applied:
    they must be saturated, all parameters must be given for
    a type expression to be valid. Therefore we cannot
    easily abstract over polymorphic type constructors and
    generalise the type of the List.map function:

    {[val map : ('a -> 'b) -> 'a list -> 'b list]}

    Since the syntax doesn't allow to replace [list] with a type variable:

    {[val invalidmap : ('a -> 'b) -> 'a 'f -> 'b 'f]}

    The purpose of this module is to be able to write such
    generalisation using defunctionalisation as described in
    the article "Lightweight Higher-Kinded Polymorphism" by
    Jeremy Yallop and Leo White.

    The type ['a 'f] is not valid, but we may write [('a,'f) app],
    where the type [app] is an extensible gadt.
    To each polymorphic type ['a p], we will associate an abstract type
    [pcode] which is interpreted by the gadt [app] such that:
    [('a,p_code) app] is isomorphic to ['a p].

    For instance, to represent the [list] type constructor,
    we define the abstract type [list_code]:

    {[type list_code]}

    and we add a [List] constructor to [app]:

    {[type (_,_) app += List : 'a list -> ('a, list_code) app]}

    The generalised [map] may then be typed:

    {[val map : ('a -> 'b) -> ('a,'f) app -> ('b,'f) app]}


    {b Uses of [app] in the generic library}.

    [app] is used to define extensible type indexed functions, see
    {!module:Generic_core_extensible}.
*)

(** {2 Type Application}
 *)

(** Module defining {!app}, suitable to be opened. *)
module T : sig
  (** Extensible GADT interpreting type application.  *)
  type (_,_) app = ..

  type 'f functorial =
    { fmap : 'a 'b . ('a -> 'b) -> ('a, 'f) app -> ('b, 'f) app }

  type 'f applicative =
    { pure : 'a . 'a -> ('a,'f) app
    ; apply : 'a 'b . ('a -> 'b, 'f) app -> ('a, 'f) app -> ('b, 'f) app
    }

  type 'f monad =
    { return : 'a . 'a -> ('a,'f) app
    ; bind : 'a 'b . ('a , 'f) app -> ('a -> ('b, 'f) app) -> ('b, 'f) app
    }

  type 't monoid =
    { mempty : 't
    ; mappend : 't -> 't -> 't
    }
end

(** Synonym for convenience, when namespace [Generic_util] is
    opened, and one doesn't want to open [App.T], one can
    refer to [App.T.app] as [App.t].
*)
type ('a,'b) t = ('a,'b) T.app

(** {2 Core parametric  types} *)
type option' = OPTION
type (_,_) t += Option : 'a option -> ('a, option') t
val get_option : ('a, option') t -> 'a option

type list' = LIST
type (_,_) t += List : 'a list -> ('a, list') t
val get_list : ('a, list') t -> 'a list

type array' = ARRAY
type (_,_) t += Array : 'a array -> ('a, array') t
val get_array : ('a, array') t -> 'a array

(** {2 Identity Functor} *)

type id = ID
type (_, _) t += Id : 'a -> ('a, id) t
val get_id : ('a, id) t -> 'a

(** {2 Constant Functor} *)

(** The type ['t const] doesn't build useful values, we use
    it as a "code" to be interpreted by [app] so that [('a, 't
    const) app] is isomorphic to ['t].

    It would have been better to make ['t const] an abstract
    type, but it then makes typechecking troublesome for the
    constructor [Const : 't -> ('a, 't const) app]
*)
type 't const = CONST

(** [('a, 'b const) app] is isomorphic to ['t] *)
type (_, _) t += Const : 'b -> ('a, 'b const) t

(** Get the argument of the [Const] constructor *)
val get_const : ('a, 'b const) t -> 'b

(** {2 Exponential Functor}
*)

(** The type ['b exponential] doesn't build useful values,
    consider it abstract. We use it as a "code" to be
    interpreted by [app] so that [('a, 'b exponential) app] is
    isomorphic to ['a -> 'b].
*)
type 'b exponential = EXPONENTIAL

(** [('a, 'b exponential) app] is isomorphic to ['a -> 'b]. *)
type (_, _) t += Exponential : ('a -> 'b) -> ('a, 'b exponential) t

(** Get the argument of the [Exponential] constructor *)
val get_exponential : ('a, 'b exponential) t -> 'a -> 'b

(** {2 Functor Composition}
*)
type ('f, 'g) comp = COMP
type (_, _) t += Comp : (('a,'f) t, 'g) t -> ('a, ('f, 'g) comp) t
val get_comp : ('a, ('f, 'g) comp) t -> (('a,'f) t, 'g) t

(** {1 Operations} *)

(** {2 Conversion} *)

val fun_of_app : 'a T.applicative -> 'a T.functorial
val fun_of_mon : 'a T.monad -> 'a T.functorial
val app_of_mon : 'a T.monad -> 'a T.applicative

(** {2 Applicative} *)

val liftA : 'f T.applicative -> ('a -> 'b) ->
  ('a, 'f) T.app -> ('b, 'f) T.app
val liftA2 : 'f T.applicative -> ('a -> 'b -> 'c) ->
  ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app
val liftA3 : 'f T.applicative -> ('a -> 'b -> 'c -> 'd) ->
 ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app -> ('d, 'f) T.app
val liftA4 : 'f T.applicative -> ('a -> 'b -> 'c -> 'd -> 'e) ->
 ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app -> ('d, 'f) T.app -> ('e, 'f) T.app


(** {2 Monad} *)

val liftM : 'f T.monad -> ('a -> 'b) ->
  ('a, 'f) T.app -> ('b, 'f) T.app
val liftM2 : 'f T.monad -> ('a -> 'b -> 'c) ->
  ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app
val liftM3 : 'f T.monad -> ('a -> 'b -> 'c -> 'd) ->
 ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app -> ('d, 'f) T.app
val liftM4 : 'f T.monad -> ('a -> 'b -> 'c -> 'd -> 'e) ->
 ('a, 'f) T.app -> ('b, 'f) T.app -> ('c, 'f) T.app -> ('d, 'f) T.app -> ('e, 'f) T.app

val join : 'a T.monad -> (('b, 'a) T.app, 'a) T.app -> ('b, 'a) T.app

(** {2 instances} *)
val id_applicative : id T.applicative
val id_monad : id T.monad
val const_applicative : 'a T.monoid -> 'a const T.applicative
