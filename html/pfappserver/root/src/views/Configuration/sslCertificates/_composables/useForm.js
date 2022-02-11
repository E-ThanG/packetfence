import { computed, ref, toRefs, watch } from '@vue/composition-api'
import i18n from '@/utils/locale'
import schemaFn from '../schema'
import {
  certificateServices,
  strings
} from '../config'

const useFormProps = {
  id: {
    type: String
  }
}

const useForm = (form, props, context) => {

  const {
    id
  } = toRefs(props)

  const { emit } = context

  const schema = computed(() => schemaFn(props))

  const title = computed(() => id.value.toUpperCase())

  const isCertificationAuthority = computed(() => {
    const { info: { ca } = {} } = form.value
    return ca
  })

  const isCertKeyMatch = computed(() => {
    const { info: { cert_key_match: { success } = {} } = {} } = form.value
    emit('cert-key-match', success)
    return success
  })

  const isChainValid = computed(() => {
    const { info: { chain_is_valid: { success } = {} } = {} } = form.value
    emit('chain-valid', success)
    return success
  })

  const isLetsEncrypt = computed(() => {
    const { info: { lets_encrypt } = {} } = form.value
    return lets_encrypt
  })

  const sortSslKeys = ['serial', 'issuer', 'not_before', 'not_after', 'subject', 'common_name']
  const fnSortSslKeys = (a, b) => {
    return sortSslKeys.indexOf(a) - sortSslKeys.indexOf(b)
  }

  // translate keys in certificate
  const certificateLocale = computed(() => {
    const { info: { certificate = {} } = {} } = form.value
    return Object.keys(certificate)
      .sort(fnSortSslKeys)
      .reduce((stack, key) => {
        return (key in strings)
          ? { ...stack, [i18n.t(strings[key])]: form.value.info.certificate[key] }
          : { ...stack, [key]: form.value.info.certificate[key] }
      }, {})
  })

  // translate keys in certificate
  const intermediateCertificatesLocale = computed(() => {
    const { info: { intermediate_cas = [] } = {} } = form.value
    return intermediate_cas.map((_ca, _i) => {
      return Object.keys(_ca)
        .sort(fnSortSslKeys)
        .reduce((stack, key) => {
          return (key in strings)
            ? { ...stack, [i18n.t(strings[key])]: form.value.info.intermediate_cas[_i][key] }
            : { ...stack, [key]: form.value.info.intermediate_cas[_i][key] }
        }, {})
    })
  })

  // translate keys in certificate
  const certificationAuthorityLocale = computed(() => {
    const { info: { ca = [] } = {} } = form.value
    return ca.map((_ca, _i) => {
      return Object.keys(_ca)
        .sort(fnSortSslKeys)
        .reduce((stack, key) => {
          return (key in strings)
            ? { ...stack, [i18n.t(strings[key])]: form.value.info.ca[_i][key] }
            : { ...stack, [key]: form.value.info.ca[_i][key] }
        }, {})
    })
  })

  const isShowCsr = ref(false)
  const doShowCsr = () => {
    isShowCsr.value = true
  }
  const doHideCsr = () => {
    isShowCsr.value = false
  }

  const services = computed(() => certificateServices[id.value] || [])

  // cosmetic props only
  const isFindIntermediateCas = ref(false)

  watch(isFindIntermediateCas, isFindIntermediateCas => {
    if (isFindIntermediateCas && 'certificate' in form.value) // clear intermediate CAs
      form.value.certificate.intermediate_cas = []
  })

  watch([form], () => {
    const { certificate: { intermediate_cas = [] } = {} } = form.value || {}
      isFindIntermediateCas.value = (intermediate_cas.length === 0)
  }, { deep: true, immediate: true })

  return {
    schema,
    certificateLocale,
    certificationAuthorityLocale,
    intermediateCertificatesLocale,
    title,
    services,

    isShowCsr,
    doShowCsr,
    doHideCsr,

    isCertificationAuthority,
    isCertKeyMatch,
    isChainValid,
    isLetsEncrypt,
    isFindIntermediateCas
  }
}

export {
  useFormProps,
  useForm
}
