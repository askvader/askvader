    let ReaderT = ./Type

in  let Monad = ./../Monad/Type

in  let extractApplicative = ./../Monad/extractApplicative

in    λ(r : Type)
    → λ(m : Type → Type)
    → λ(monad : Monad m)
    →   { lift =
            λ(a : Type) → (./transformer r).lift m monad a
        , ask =
            ./ask r m (extractApplicative m monad)
        , asks =
            λ(a : Type) → ./asks r m (extractApplicative m monad) a
        , local =
              λ(a : Type)
            → λ(f : r → r)
            → λ(reader : ReaderT r m a)
            → ./local r m a f reader
        }
      ∧ ./monad r m monad
